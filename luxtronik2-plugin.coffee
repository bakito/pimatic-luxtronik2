# #Plugin template

# This is an pimatic plugin to connect to heat pumps based on the luxtronik 2.0 control.
# It uses the implementation from https://github.com/coolchip/luxtronik2

# ##The plugin code

module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include your own dependencies with nodes global require function:
  Luxtronik = require 'luxtronik2'
  DateFormat = require 'dateformat'
  commons = require('pimatic-plugin-commons')(env)

  # ###Luxtronik2Plugin class
  class Luxtronik2Plugin extends env.plugins.Plugin

    # ####init()
    #
    init: (app, @framework, config) =>
      @host = config.host
      @port = config.port
      @interval = config.interval
      @pump = new Luxtronik(@host, @port)


      # register devices
      deviceConfigDef = require("./device-config-schema.coffee")
      @framework.deviceManager.registerDeviceClass("Luxtronic2Data", {
        configDef: deviceConfigDef.Luxtronic2Data,
        createCallback: (config, lastState) =>
          return new Luxtronic2DataDevice config, @, lastState
      })

  class Luxtronic2DataDevice extends env.devices.Device
    attributes:
      temperatureOutside:
        description: "The current outside temperature"
        type: "number"
        unit: '°C'
        acronym : "Outside"
      temperatureOutsideAvg:
        description: "The average outside temperature"
        type: "number"
        unit: '°C'
        acronym : "Outside avg"
      temperatureHotWater:
        description: "The current water temperature"
        type: "number"
        unit: '°C'
        acronym : "Water current"
      temperatureHotWaterTarget:
        description: "The target water temperature"
        type: "number"
        unit: '°C'
        acronym : "Water target"
      heatpumpState:
        description: "The current heat pump state"
        type: "string"
        acronym : "State"
      heatpumpExtendedState:
        description: "The current extended heat pump state"
        type: "string"
        acronym : "Extended State"
      lastError:
        description: "The last error"
        type: "string"
        acronym : "Last Error"

    temperatureOutside: 0.0
    temperatureOutsideAvg: 0.0
    temperatureHotWater: 0.0
    temperatureHotWaterTarget: 0.0
    heatpumpState:'N/A'
    heatpumpExtendedState:'N/A'
    lastError:'N/A'


    constructor: (@config, @plugin, @service) ->
      @id = @config.id
      @base = commons.base @, @config.class unless @base?
      @name = @config.name
      @pump = @plugin.pump
      @interval = 1000 * @plugin.interval
      super()

      process.nextTick () =>
        @_requestUpdate()

      @on 'data', ((data) =>
        @temperature_supply = data.values.temperature_supply
        env.logger.info(@temperature_supply)
      )

    destroy: () ->
      @base.cancelUpdate()
      super()

    _requestUpdate: ->
      pump = @pump
      new Promise((resolve, reject) ->
        pump.read false, (data) ->
          if data.error
            reject data.error
          else
            resolve data
          return
        return
      ).then((data) =>

        @temperatureOutside = data.values.temperature_outside
        @temperatureOutsideAvg = data.values.temperature_outside_avg
        @temperatureHotWater = data.values.temperature_hot_water
        @temperatureHotWaterTarget = data.values.temperature_hot_water_target
        @heatpumpState = data.values.heatpump_state_string
        @heatpumpExtendedState = data.values.heatpump_extendet_state_string

        @lastError= @_extractError data.values.errors

        env.logger.debug('data received')

        @emit "temperatureOutside", @temperatureOutside
        @emit "temperatureOutsideAvg", @temperatureOutsideAvg
        @emit "temperatureHotWater", @temperatureHotWater
        @emit "temperatureHotWaterTarget", @temperatureHotWaterTarget
        @emit "heatpumpState", @heatpumpState
        @emit "heatpumpExtendedState", @heatpumpExtendedState
        @emit "lastError", @lastError
      ).catch((error) =>
        if (error == 'busy')
          env.logger.debug('The device is currently busy.')
        else
          env.logger.error(error)
      ).finally(() =>
        @base.scheduleUpdate @_requestUpdate, @interval
      )

    _extractError: (errors) ->
      if (errors && errors[0])
        error = errors[0];

        if new Date().toDateString() == error.date.toDateString()
          errorMessage = DateFormat(error.date, 'dd.MM.yyyy HH:MM:ss') + ' - ' + error.message + ' (' + error.code + ')'
          env.logger.debug('Got luxtronik error: ', errorMessage)
          return errorMessage

      return 'N/A'

    getTemperatureOutside: -> Promise.resolve @temperatureOutside
    getTemperatureOutsideAvg: -> Promise.resolve @temperatureOutsideAvg
    getTemperatureHotWater: -> Promise.resolve @temperatureHotWater
    getTemperatureHotWaterTarget: -> Promise.resolve @temperatureHotWaterTarget
    getHeatpumpState: -> Promise.resolve @heatpumpState
    getHeatpumpExtendedState: -> Promise.resolve @heatpumpExtendedState
    getLastError: -> Promise.resolve @lastError

  # Create a instance of luxtronik2 plugin
  luxtronik2 = new Luxtronik2Plugin
  # and return it to the framework.
  return luxtronik2
