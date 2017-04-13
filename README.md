pimatic-luxtronik2-plugin
=======================

[![Build Status](https://travis-ci.org/bakito/pimatic-luxtronik2.svg?branch=master)](https://travis-ci.org/bakito/pimatic-luxtronik2)

This is a pimatic plugin to connect to heat pumps based on the luxtronik 2.0 control.
It uses the implementation from https://github.com/coolchip/luxtronik2


## Configuration

You can load the plugin by editing your `config.json` to include the following in the `plugins` section. The property 
`interval` (default is 60s) specifies the time interval in seconds for updating the data set. The property `host` defines the 
host name or ip of the Luxtronik2 service. The `port` optionally be defined (default ist 8888). 

    {
      "plugin": "luxtronik2",
      "host": "luxtronik host",
      "port": 8888
      "active": true
    },

The plugin provides on device `Luxtronic2Data` which currently supports the following attributes.

    {
      "id": "luxtronik",
      "name": "Luxtronik2",
      "class": "Luxtronic2Data",
      "attributes": [
        "temperatureOutside",
        "temperatureOutsideAvg",
        "temperatureHotWater",
        "temperatureHotWaterTarget",
        "heatpumpState"
      ]
    },


## Configuration
Until released, this plugin can pe installed by executing the following command in the pimatic-app directory.

`npm install bakito/pimatic-luxtronik2#master --unsafe-perm`


