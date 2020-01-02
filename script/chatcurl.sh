#!/bin/bash

function wxalarm() {
        curl -G  --data-urlencode "user=$1" --data-urlencode "appid=trionotice" --data-urlencode "token=bcc6644ba8cfcf3284311027e18186a4" --data-urlencode "text={\"title\":\"$2\",\"alarm\":\"$3\"}"  "http://triotest.sanjiaoshou.net/Monitor/alarmapi.php"
}

#时间戳
filestmp=$(date "+%Y-%m-%d")

for i in $(seq 1 100)
do
    uid="triotest$RANDOM"
    curl -H "Content-Type:application/json" -X POST -s -w %{time_namelookup}::%{time_connect}::%{time_starttransfer}::%{time_total}::%{speed_download}"\n" --data '{"service_ver":"1.0","bot_name":"dm87988D2068AB0527","bot_ver":"1","user_id":"$uid","bot_mode":0,"query":"你是谁啊","req_type":"chat","send_time_ms":"1454319650000","query_time_ms":"1454319650000","debug":1,"callback_msg":"anything here will send back","stat_info":{"ip":"192.168.1.1","device_id":"asdwrgh","user_group":"user","os":"android","os_ver":"1.4.0"},"location":{"la":40.0433,"lo":116.269,"address":"北京市海淀区软件园西三路","country":"中国","province":"北京市","city":"北京市","district":"海淀区","street":"软件园西三路"}}' http://service.sanjiaoshou.net/TrioRobot/index.php -o /dev/null >> chatcurl.$filestmp
    sleep 1
done
#超过1s数量
timeoutnum=$(tail -100 chatcurl.$filestmp | awk -F "::" '{if($4>=1)a++}END{print a}')

[[ $timeoutnum -gt 10 ]] && wxalarm "LiYan" "【北京办公室网络】聊天serivce服务1s超时比例" "五分钟内100条请求1s超时占比$timeoutnum%"
