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
echo 'stable version from redis.io.'
echo '======================================'
echo
echo 'Press enter to continue or Ctrl+c to cancel'
read usercontinue
clear

echo Cleaning up before starting...
service redis stop > /dev/null 2>&1
service redis-server stop > /dev/null 2>&1
service redis_6379 stop > /dev/null 2>&1

deluser redis > /dev/null 2>&1
rm -rf /tmp/redis-*
rm -rf /usr/local/bin/redis-*
rm -rf /etc/redis/
rm -rf /var/log/redis_*
rm -rf /var/lib/redis/
rm -rf /etc/init.d/redis_*
rm -rf /var/run/redis_*

echo Updating Apt sources...
apt-get update

echo Enter your desired redis password:
read REDISPASSWORD
echo Installing Redis stable version...
cd /tmp
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable
make
make test
make install
echo Successfully installed Redis...

echo Configuring Redis...
cd ~
rm -rf /etc/redis
mkdir /etc/redis
cp /tmp/redis-stable/redis.conf /etc/redis
sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
sed -i 's/dir \.\//dir \/var\/lib\/redis/g' /etc/redis/redis.conf

sed -i 's/# requirepass foobared/requirepass '"$REDISPASSWORD"'/g' /etc/redis/redis.conf
echo Renaming risky commands...
sed -i 's/# AOF file or transmitted to slaves may cause problems\./# AOF file or transmitted to slaves may cause problems\.\nrename-command FLUSHDB BCL_FLUSHDB\nrename-command DEBUG BCL_DEBUG\nrename-command CONFIG BCL_CONFIG\nrename-command SAVE BCL_SAVE\nrename-command PEXPIRE BCL_PEXPIRE\nrename-command DEL BCL_DEL\nrename-command BGREWRITEAOF BCL_BGREWRITEAOF\nrename-command BGSAVE BCL_BGSAVE\nrename-command SPOP BCL_SPOP\nrename-command SREM BCL_SREM\nrename-command RENAME BCL_RENAME\n/g' /etc/redis/redis.conf

echo Adding redis to your service...
cat << EOF > /etc/systemd/system/redis.service
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo Successfully configured Redis...
echo Creating Redis user...
rm -rf /var/lib/redis
adduser --system --group --no-create-home redis
mkdir /var/lib/redis
chown redis:redis /var/lib/redis
chmod 770 /var/lib/redis

echo Enabling Redis on restart...
systemctl enable redis
systemctl restart redis
echo Optimizing Redis server.
echo never > /sys/kernel/mm/transparent_hugepage/enabled
sysctl vm.overcommit_memory=1
sysctl -w net.core.somaxconn=65535
sed -i '$i \echo never > /sys/kernel/mm/transparent_hugepage/enabled\n' /etc/rc.local
sed -i '$i \vm.overcommit_memory = 1\n' /etc/sysctl.conf
sed -i '$i \sysctl -w net.core.somaxconn=65535\n' /etc/rc.local

echo Redis setup is successfull!
