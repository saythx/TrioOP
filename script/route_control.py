#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Create date: 2018-10-17
Last update: 2018-10-23
Version: 1.1
Description：登陆限制需求：
             X.X网段不允许访问外网
             root用户登陆可以访问外网
             root用户登陆情况下普通用户无法禁止访问外网，除非root用户也不访问外网
             普通用户登陆不允许访问外网
             普通用户可以申请一段时间访问外网
Usage method：放入crontab中自定义执行间隔，不给参数时，除非root用户登陆，否则不允许自行访问外网，
              可以传递1个参数，必须是数字，可以是浮点数，表示普通用户可以访问外网的时间,单位为小时。
                添加关闭打开功能
Author: Yefei
'''
import psutil
import os
import sys
import datetime

# 网关ip地址设定
GW_IP = "10.0.3.1"


def help():
    print("""使用方式：
          1， %s  不加参数使用时，除非root登陆，否则不允许访问外网
          2， %s float(sys.argv[1]) 可以传递一个参数，当参数是数字得时候，表示可以访问外网的时间长度，单位为小时。
          3， %s open|close  表示打开或关闭外网，不限时长
          """ % (sys.argv[0], sys.argv[0], sys.argv[0]))
    sys.exit()


def isfloat(value):
    try:
        x = float(value)
    except TypeError:
        return False
    except ValueError:
        return False
    except Exception as e:
        return False
    else:
        return True


# 删除网关函数
def delGateWay():
    CMD = 'route del default gw %s' % (GW_IP)
    os.popen(CMD)


# 添加网关函数
def addGateWay():
    CMD = 'route add default gw %s' % (GW_IP)
    os.popen(CMD)


# 检查网关是否存在
def gateWayCheck():
    flag = False
    for line in routList:
        if GW_IP in line:
            flag = True
            return flag


# 检查用户是否是root
def userCheck():
    flag = False
    for User in userList:
        if User.name == "root":
            print("用户是root")
            flag = True
            return flag


# 网关添加
def userOnline(flag):
    print(flag)
    if flag:
        print("检测网关已存在，退出程序")
        sys.exit()
    else:
        print("添加网关")
        addGateWay()


# 网关删除
def userOffline(flag):
    if flag:
        print("检测网关已存在，删除网关")
        delGateWay()
    else:
        print("检测网关不存在，退出程序")
        sys.exit()


# 将普通用户访问外网的时间节点写入文件，当到达此事件后去掉网关
def FileForTime(scheme, *args):
    if scheme == "w":
        with open("/root/controltime", "w") as recordTime:
            now = datetime.datetime.now()
            endTime = now + datetime.timedelta(hours=args[0])
            endStrTime = endTime.strftime('%Y-%m-%d %H:%M:%S')
            recordTime.write(endStrTime)
            if now < endTime:
                return True
            else:
                return False
    elif scheme == "r":
        with open("/root/controltime", "r") as recordTime:
            endStrTime = recordTime.readline().strip()
            if len(endStrTime) > 10:
                endTime = datetime.datetime.strptime(endStrTime, '%Y-%m-%d %H:%M:%S')
                now = datetime.datetime.now()
                if now < endTime:
                    return True
                else:
                    return False
            else:
                return False


if __name__ == '__main__':
    routList = []
    routList = os.popen("route -n")
    userList = psutil.users()
    if len(sys.argv) >= 2:
        if sys.argv[1] == "open":
            userOnline(gateWayCheck())
        elif sys.argv[1] == "close":
            userOffline(gateWayCheck())
        elif isfloat(sys.argv[1]):
            hoursLen = float(sys.argv[1])
            print(hoursLen)
            if FileForTime('w', hoursLen):
                print("用户可以上网")
                userOnline(gateWayCheck())
            else:
                print("用户不可以上网")
                userOffline(gateWayCheck())
        elif sys.argv[1] == help:
            help()
        else:
            help()
    else:
        if len(userList) > 0 and userCheck():
            userOnline(gateWayCheck())
        elif os.path.exists("/root/controltime"):
            if FileForTime("r"):
                userOnline(gateWayCheck())
            else:
                userOffline(gateWayCheck())
        else:
            userOffline(gateWayCheck())

