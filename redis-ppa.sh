#!/bin/bash

# MIT License
# 
# Copyright (c) 2017 John Sayo
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or sudo" 1>&2
   exit 1
fi
clear
echo Redis Installation and setup...
echo '==============WARNING================='
echo 'This script will remove your existing redis installation'
echo 'and all redis user data. This script will install the latest'
echo 'stable version from ppa:chris-lea/redis-server repository'
echo '======================================'
echo
echo 'Press enter to continue or Ctrl+c to cancel'
read usercontinue
clear

echo Cleaning up before starting...
service redis-server stop > /dev/null 2>&1
apt-get purge -y redis-server
apt-get autoremove -y

echo Enter your desired redis password:
read REDISPASSWORD

echo Updating Apt sources...
add-apt-repository ppa:chris-lea/redis-server -y
echo Updating...
apt-get update
echo Installing Redis Server
apt-get install redis-server -y
service redis-server stop > /dev/null 2>&1
echo Successfully installed Redis...

echo Configuring Redis...
sed -i 's/# requirepass foobared/requirepass '"$REDISPASSWORD"'/g' /etc/redis/redis.conf
echo Renaming risky commands...
sed -i 's/# AOF file or transmitted to slaves may cause problems\./# AOF file or transmitted to slaves may cause problems\.\nrename-command FLUSHDB BCL_FLUSHDB\nrename-command DEBUG BCL_DEBUG\nrename-command CONFIG BCL_CONFIG\nrename-command SAVE BCL_SAVE\nrename-command PEXPIRE BCL_PEXPIRE\nrename-command DEL BCL_DEL\nrename-command BGREWRITEAOF BCL_BGREWRITEAOF\nrename-command BGSAVE BCL_BGSAVE\nrename-command SPOP BCL_SPOP\nrename-command SREM BCL_SREM\nrename-command RENAME BCL_RENAME\n/g' /etc/redis/redis.conf
sed -i 's/appendonly no/appendonly yes/g' /etc/redis/redis.conf
sed -i 's/tcp-backlog 511/tcp-backlog 65535/g' /etc/redis/redis.conf
echo Successfully configured Redis...

echo Optimizing Redis server.
echo never > /sys/kernel/mm/transparent_hugepage/enabled
sysctl -w vm.overcommit_memory=1
sysctl -w net.core.somaxconn=65535
sysctl -w vm.swappiness=0
sysctl -w net.ipv4.tcp_sack=1
sysctl -w net.ipv4.tcp_timestamps=1
sysctl -w net.ipv4.tcp_window_scaling=1
sysctl -w net.ipv4.tcp_congestion_control=cubic
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.tcp_tw_recycle=1
sysctl -w net.ipv4.tcp_max_syn_backlog=65535
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sed -i '/echo never > \/sys\/kernel\/mm\/transparent_hugepage\/enabled/g' /etc/rc.local
sed -i '$i \echo never > /sys/kernel/mm/transparent_hugepage/enabled' /etc/rc.local
sed -i '/^vm.overcommit_memory = /{h;s/=.*/= 1/};${x;/^$/{s//vm.overcommit_memory = 1/;H};x}' /etc/sysctl.conf
sed -i '/^vm.swappiness = /{h;s/=.*/= 0/};${x;/^$/{s//vm.swappiness = 0/;H};x}' /etc/sysctl.conf
sed -i '/^net.ipv4.tcp_sack = /{h;s/=.*/= 1/};${x;/^$/{s//net.ipv4.tcp_sack = 1/;H};x}' /etc/sysctl.conf
sed -i '/^net.ipv4.tcp_timestamps = /{h;s/=.*/= 1/};${x;/^$/{s//net.ipv4.tcp_timestamps = 1/;H};x}' /etc/sysctl.conf
sed -i '/^net.ipv4.tcp_window_scaling = /{h;s/=.*/= 1/};${x;/^$/{s//vm.swappiness = 1/;H};x}' /etc/sysctl.conf
sed -i '/^net.ipv4.tcp_congestion_control = /{h;s/=.*/= cubic/};${x;/^$/{s//net.ipv4.tcp_congestion_control = cubic/;H};x}' /etc/sysctl.conf
sed -i '/^net.ipv4.tcp_syncookies = /{h;s/=.*/= 1/};${x;/^$/{s//net.ipv4.tcp_syncookies = 1/;H};x}' /etc/sysctl.conf
sed -i '/^net.ipv4.tcp_tw_recycle = /{h;s/=.*/= 1/};${x;/^$/{s//net.ipv4.tcp_tw_recycle = 1/;H};x}' /etc/sysctl.conf
sed -i '/^net.ipv4.tcp_max_syn_backlog = /{h;s/=.*/= 65535/};${x;/^$/{s//net.ipv4.tcp_max_syn_backlog = 65535/;H};x}' /etc/sysctl.conf
sed -i '/^net.core.somaxconn = /{h;s/=.*/= 65535/};${x;/^$/{s//net.core.somaxconn = 65535/;H};x}' /etc/sysctl.conf
sed -i '/^net.core.rmem_max = /{h;s/=.*/= 16777216/};${x;/^$/{s//net.core.rmem_max = 16777216/;H};x}' /etc/sysctl.conf
sed -i '/^net.core.wmem_max = /{h;s/=.*/= 16777216/};${x;/^$/{s//net.core.wmem_max = 16777216/;H};x}' /etc/sysctl.conf

echo Successfully optimized Redis...
echo Enabling Redis on restart...
update-rc.d redis-server defaults
service redis restart
echo Redis setup is successfull!

