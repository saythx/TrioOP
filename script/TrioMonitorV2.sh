#!/bin/bash

if [[ "$1" == "start" ]];then
   sh /home/trio/Monitor/MonitorUniversalV2.sh CBot server.pid /home/trio/Release/Project/CBot/Shell/all.sh zjkaliyun LiuDun,JiangShangWei,LiYan,TianRong &>/home/trio/Monitor/log/CBot.$(date +'%Y-%m-%d') &
   echo $! > monitor.pid
   exit
fi

if [[ "$1" == "stop" ]];then
   kill -9 $(cat monitor.pid)
   rm monitor.pid
fi
