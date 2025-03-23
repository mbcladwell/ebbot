#! /bin/bash
pid=$(ps aux | grep /usr/bin/mcron | awk 'NR==1{print $2}')
if [ ${pid} ]; then kill -9 ${pid}; fi
nohup /usr/bin/mcron > mcron-start-log.txt 2>&1 
