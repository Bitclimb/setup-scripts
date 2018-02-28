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
rm -rf /tmp/redis*
rm -rf /usr/local/bin/redis*
rm -rf /etc/redis
rm -rf /var/log/redis*
rm -rf /var/lib/redis
rm -rf /etc/init.d/redis*
rm -rf /var/run/redis*
rm -rf /etc/systemd/system/redis*
rm -rf /etc/redis
rm -rf /var/redis

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
echo Creating config folders
mkdir /etc/redis
mkdir /var/redis
mkdir /var/redis/6379

echo Copying config file
cp /tmp/redis-stable/redis.conf /etc/redis/6379.conf

echo Creating Redis user...
adduser --system --group --no-create-home redis
chown redis:redis /var/redis
chmod 700 /var/redis
chown redis:root /etc/redis/6379.conf
chmod 600 /etc/redis/6379.conf

echo Configuring Redis...
echo Copying redis init script
cp /tmp/redis-stable/utils/redis_init_script /etc/init.d/redis
sed -i 's/CLIEXEC=\/usr\/local\/bin\/redis-cli/CLIEXEC=\/usr\/local\/bin\/redis-cli\nREDISPW='"$REDISPASSWORD"'/g' /etc/init.d/redis
sed -i 's/CLIEXEC -p $REDISPORT shutdown/CLIEXEC -p $REDISPORT -a $REDISPW shutdown/g' /etc/init.d/redis
cd ~

sed -i 's/dir \.\//dir \/var\/redis\/6379/g' /etc/redis/6379.conf
sed -i 's/daemonize no/daemonize yes/g' /etc/redis/6379.conf
sed -i 's/logfile \"\"/logfile \/var\/log\/redis_6379.log/g' /etc/redis/6379.conf


sed -i 's/# requirepass foobared/requirepass '"$REDISPASSWORD"'/g' /etc/redis/6379.conf
echo Renaming risky commands...
sed -i 's/# AOF file or transmitted to slaves may cause problems\./# AOF file or transmitted to slaves may cause problems\.\nrename-command FLUSHDB BCL_FLUSHDB\nrename-command DEBUG BCL_DEBUG\nrename-command CONFIG BCL_CONFIG\nrename-command SAVE BCL_SAVE\nrename-command PEXPIRE BCL_PEXPIRE\nrename-command DEL BCL_DEL\nrename-command BGREWRITEAOF BCL_BGREWRITEAOF\nrename-command BGSAVE BCL_BGSAVE\nrename-command SPOP BCL_SPOP\nrename-command SREM BCL_SREM\nrename-command RENAME BCL_RENAME\n/g' /etc/redis/6379.conf

update-rc.d redis defaults

echo Successfully configured Redis...

service redis start


echo Redis setup is successfull!
