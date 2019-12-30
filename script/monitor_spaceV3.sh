#!/bin/bash
#update:增加各个磁盘挂载点目录空间监控
LANG="zh_CN.UTF-8"
HOST_ip=`hostname -i`
HOST_name=`hostname -s`
TRIGGERS=90

html_format() {
    echo '<html>'
    echo '<h3>' 服务器：$HOST_ip"（ $HOST_name ）"，$DISK 目录使用率大于："$TRIGGERS%"，当前使用率："$USAGE"，请相关用户及时清理！ '<h3>'
    echo '<body>'
    echo '<table border="1">'
    
    for i in {1..10};do
    echo '<tr>'
    echo '<td>' `echo "$SPACE_top" |sed -n "${i}p" |awk '{print $1}'` '</td>'
    echo '<td>' `echo "$SPACE_top" |sed -n "${i}p" |awk '{print $2}'` '</td>'
    echo '</tr>'
    done

    echo '</table>'
    echo '</body>'
    echo '</html>'
}

MAIL_list() {
    for i in $USER_top
    do
    echo $i@trio.ai
    done
}

SEND() {
/usr/local/bin/sendEmail -o message-charset=utf8 -f internal-notice@trio.ai -t `MAIL_list` trioinf@trio.ai -s smtp.mxhichina.com -u "$SUBJECT" -o message-content-type=html -o message-charset=utf8 -xu internal-notice@trio.ai -xp TrioInternalNotice2017 -m `html_format`
}

for i in {a..b};do
    USAGE=`df -h |grep dev/sd"$i" |awk '{print $5}'`
    if [ `echo "$USAGE" |sed 's/%//g'` -gt $TRIGGERS ];
         then  
         DISK=`df -h |grep /dev/sd"$i" |awk '{print $6}'`
CHARS=`iconv -t GB2312 -f UTF-8 << EOF
目录使用情况
EOF`
         SUBJECT=$DISK$CHARS
         cd $DISK
         SPACE_top=`du -sh * |sort -hr |awk '{print $1 "\t       \t" $2}' |head`
         USER_top=`du -sh * |sort -hr |awk '{print $2}' |head |tr '[A-Z]' '[a-z]'`
         SEND
    fi 
done
