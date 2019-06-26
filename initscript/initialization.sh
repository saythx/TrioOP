#!/bin/bash
#author: yefei
#date:2019/02/27
#update:2019/4-10
#version:4.6
#description： 系统初始化时执行脚本
#添加nc下载
[[ $# -ne 1 ]] && echo "usage: $0 start" && exit 0
if [[ `uname -r` =~ .*el7.* ]] 
then
        :
else
        echo -e "\033[31mthis script only used for el7\033[0m"
        exit 1
fi
if [[ $1 == start ]]
then
        echo -e "\033[31minitialize the linux system.....\033[0m"
else
        echo -e "这个脚本用于初始化系统，使用时请输入：
\033[31m$0 start\033[0m"
        exit 1
fi
[[ $USER != "root" ]] && echo "must use this script by root" && exit 1

[[ -f /root/.initialization ]] && echo "the system has initialized,do not need exec again" && exit 0
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/'  /etc/selinux/config
[[ -f /usr/bin/wget ]] || yum -y install wget
#添加epel源，生成缓存
[[ ! -f /etc/yum.repos.d/epel.repo ]] && wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo && yum makecache
#安装程序
yum -y install libjpeg libjpeg-devel libpng libpng-devel freetype \
                    freetype-devel libxml2 libxml2-devel mysql pcre-devel \
                    pcre* openssl* zlib zlib-devel wget zip unzip gcc-c++ \
                    lsof zlib gcc libstdc++ libstdc++-devel lrzsz vim mailx bc nc\
                    python2-pip  python-devel bash-argsparse bash-completion bash-completion-extras python36 python36-devel python36-pip ntp
([[ -f /usr/bin/pip3.6 ]] && pip3.6 install --upgrade pip) || ([[ -f /usr/bin/pip ]] && pip install --upgrade pip)
[[ -f /usr/bin/pip3.6 ]] && pip3.6 install redis kafka-python
#更新pip，安装第三方python库                   
([[ -f /usr/bin/pip2 ]] && pip2 install --upgrade pip) || ([[ -f /usr/bin/pip ]] && pip install --upgrade pip)
#[[ -f /usr/bin/pip3 ]] && pip3 install --upgrade pip 
([[ -f /usr/bin/pip2 ]] && pip2 install wheel && pip2 install -i https://pypi.tuna.tsinghua.edu.cn/simple \
                                        requests scons six pyes urllib3 certifi bs4 beautifulsoup4 chardet idna thrift==0.10.0 \
                                        slip singledispatch virtualenv)  || ([[ -f /usr/bin/pip ]] && pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
                                        requests scons six pyes urllib3 certifi bs4 beautifulsoup4 chardet idna thrift==0.10.0 \
                                        slip singledispatch virtualenv)
#检查文件limits.conf是否有改动，没有改动添加系统限定
[[ `stat -c "%Y" /etc/security/limits.d/20-nproc.conf` -lt `stat -c "%Z" /etc/security/limits.d/20-nproc.conf` && \
`stat -c "%Y" /etc/security/limits.conf` -lt `stat -c "%Z" /etc/security/limits.conf` ]] && echo -e "*          -       nofile    120000\n\
*          -       nproc     120000\n*          soft    core      unlimited\n\
*          soft    nproc     unlimited\n*          hard    nproc     unlimited" > /etc/security/limits.d/20-nproc.conf
#检查 /etc/mail.rc是否有改动
[[ `stat -c "%Y" /etc/mail.rc` -lt `stat -c "%Z" /etc/mail.rc` ]] && echo -e "set from=internal-notice@trio.ai\n\
set smtp=smtp.mxhichina.com\n\
set smtp-auth-user=internal-notice@trio.ai\n\
set smtp-auth-password="TrioInternalNotice2017"\n\
set smtp-auth=login" >> /etc/mail.rc

#添加显示设置，方便区分服务器
[[ `stat -c "%Y" /etc/profile` -lt `stat -c "%Z" /etc/profile` ]] && cat >> /etc/profile << 'EOF'
if [ "$SSH_CONNECTION" != '' -a "$TERM" != 'linux' ]; then  
declare -a HOSTIP  
HOSTIP=`echo $SSH_CONNECTION |awk '{print $3}'`  
export PROMPT_COMMAND='echo -ne "\033]0;${USER}@$HOSTIP:[${HOSTNAME%%.*}]:${PWD/#$HOME/~} \007"' 
fi 
EOF
#添加history记录操作时间
HISTORY_TIME=`cat /etc/profile | grep 'HISTTIMEFORMAT'`
if [ "$HISTORY_TIME" = "" ];then
echo 'export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "' >> /etc/profile
. /etc/profile
fi
#设置vim参数
[[ `stat -c "%Y" /etc/vimrc` -lt `stat -c "%Z" /etc/vimrc` ]] && cat >> /etc/vimrc << 'EOF'
set nonu                        "取消数字序号
set nocursorline            "取消下划线
set noautoindent          "取消自动缩进
set nosmartindent        "取消自动缩进
set nocindent                "取消自动缩进
set ignorecase              "搜索忽略大小写
set laststatus=2            "总是显示状态栏
set ruler                        "显示光标当前位置
set hlsearch                  "高亮显示搜索结果
syntax enable               "开启语法高亮功能
syntax on                       "允许用指定语法高亮配色方案替换默认方案
set expandtab               "将制表符扩展为空格
set tabstop=4               "设置编辑时制表符占用空格数
set shiftwidth=4            "设置格式化时制表符占用空格数
set mouse-=a                "鼠标复制
"TAB替换为空格：
:set ts=4                       "制表符长度4个空格
:set expandtab              "将制表符扩展为空格
:%retab!                        
EOF
# read -t 60 -p "是否添加iptables (yes/no)(default=no):" CONFIRM
# CONFIRM=${CONFIRM:-no}
# if [[ "$CONFIRM" =~ ^(y|Y)(es|ES)?$ ]];
# then
#     [[ -f /etc/rc.d/rc.local ]] || touch /etc/rc.d/rc.local
#     [[ -x /etc/rc.d/rc.local ]] || chmod +x /etc/rc.d/rc.local
#     IPTABLE_CHECK=`cat /etc/rc.d/rc.local | grep 'iptables'`
#     [[ ${IPTABLE_CHECK} == "" ]] && cat >> /etc/rc.d/rc.local << 'EOF'
# iptables -A INPUT -s 172.16.0.0/24 -j ACCEPT
# iptables -A INPUT -s 10.0.0.0/16 -j ACCEPT
# iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
# iptables -A INPUT -s 127.0.0.1 -d 127.0.0.1 -j ACCEPT
# iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
# iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
# iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
# iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
# iptables -A INPUT -m state --state INVALID -j DROP
# iptables -P INPUT DROP
# iptables -P FORWARD DROP
# iptables -P OUTPUT ACCEPT
# EOF
#     . /etc/rc.d/rc.local
# fi
touch /root/.initialization
