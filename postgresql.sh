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
echo Postgres 9.6 Installation and setup...
echo
echo '==============WARNING================='
echo
echo 'This script will remove your existing postgresql installation'
echo 'and all postgresql databases, users and user data. This script will install'
echo 'Postgresql 9.6 and Plv8 module'
echo
echo '======================================'
echo
echo 'Press enter to continue or Ctrl+c to cancel'
read usercontinue
clear

if [ -f /etc/os-release ]; then
	. /etc/os-release
	UBUNTU=UBUNTU_CODENAME
elif [ -f /etc/upstream-release/lsb-release ]; then
	. /etc/upstream-release/lsb-release
	UBUNTU=DISTRIB_CODENAME
fi

if [ "$UBUNTU" == 'trusty' ]; then
	PGREPO="deb https://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
elif [ "$UBUNTU" == 'xenial' ]; then
	PGREPO="deb https://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main"
else
	echo "This script is intended for Ubuntu trust and xenial versions only" 1>&2
	exit 1
fi

echo Cleaning up before starting...
service postgresql stop > /dev/null 2>&1
echo Remove any postgresql installation...
apt-get --purge remove postgresql*
rm -r /etc/postgresql/
rm -r /etc/postgresql-common/
rm -r /var/lib/postgresql/
deluser postgres > /dev/null 2>&1
groupdel postgres > /dev/null 2>&1

add-apt-repository "$PGREPO"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo Updating Apt sources...
apt-get update

echo Database user: 
read dbuser
echo Database name: 
read dbname
echo Database pw: 
read dbpw
echo Creating user $dbuser
sudo -Hiu postgres createuser $dbuser
sudo -Hiu postgres psql -c 'ALTER USER '"$dbuser"' WITH PASSWORD '"'$dbpw'"';'

echo Creating plv8 extension...
sudo -Hiu postgres psql -d template1 -c 'CREATE EXTENSION IF NOT EXISTS plv8;'

echo Creating uuid-ossp extension...
sudo -Hiu postgres psql -d template1 -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'

echo Creating database $dbname
sudo -Hiu postgres psql -c 'CREATE DATABASE '"$dbname"' OWNER '"$dbuser"';'
echo Changing schema owner to $dbuser
sudo -Hiu postgres psql -d $dbname -c 'ALTER SCHEMA public OWNER TO '"$dbuser"';'

echo Creating configuration back ups
cp /etc/postgresql/9.6/main/pg_hba.conf /etc/postgresql/9.6/main/pg_hba.conf.bak
cp /etc/postgresql/9.6/main/postgresql.conf /etc/postgresql/9.6/main/postgresql.conf.bak


echo Restarting postgresql service...
service postgresql stop
service postgresql start

echo Postgres setup is now configured to listen locally
echo If you want to postgres to listen to other network
echo you must edit etc/postgresql/9.6/main/postgresql.conf
echo and /etc/postgresql/9.6/main/pg_hba.conf.
echo
echo Postgres setup completed successfully.
