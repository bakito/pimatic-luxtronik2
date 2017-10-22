#!/bin/bash
basename "$0"
echo "==============================================="
echo "Starting pimatic"
cd pimatic-app

timeout 60s node_modules/pimatic/pimatic.js | tee pimatic.log


grep -q "Listening for HTTP-request on port" pimatic.log
if [ $? -eq 1 ] ; then
  echo "pimatic could not be started correctly"
  exit 1
fi
falsePositives=( "\[pimatic-luxtronik2\] { \[Error: connect ECONNREFUSED 127.0.0.1:8888" )

for fp in "${falsePositives[@]}"
do
  sed -i "/${fp}/d" pimatic.log
done

errorWords=( "Invalid" "Error" "TypeError" "exception" )
for ew in "${errorWords[@]}"
do
  grep -q "${ew}" pimatic.log
  if [ $? -eq 0 ] ; then
    echo "ERROR: The log shows the rollowing unexpected line:"
    echo "==================================================="
    grep "${ew}" pimatic.log
    exit 1
  fi
done