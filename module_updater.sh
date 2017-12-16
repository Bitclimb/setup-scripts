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

if [[ $EUID -eq 0 ]]; then
   echo "This script must is not inteded to be ran as root or sudo" 1>&2
   exit 1
fi

if ! which node > /dev/null && ! which npm > /dev/null; then
	echo "Nodejs and Npm must be installed"
	exit 1
fi

generate_deps () {	
cd "$1"
node -p << EOF
const pkgjson = require('./package.json')
const fs = require('fs')
const deps = Object.keys(pkgjson.dependencies)
let devdeps = []
if(pkgjson.devDependencies){
	devdeps = Object.keys(pkgjson.devDependencies)
}
const alldeps = deps.concat(devdeps).join(' ')

fs.writeFileSync('deps.txt',alldeps)
EOF
rm -rf node_modules package-lock.json > /dev/null 2>&1
npm install `cat deps.txt` --save
rm -rf deps.txt > /dev/null 2>&1
}

start () {
echo 'Enter the app relative directory (eg. mynodejsapp or /home/user/mynodejsapp) or CTRL+c to close:'
read APPDIR
[ ! -d "$APPDIR" ] && echo "Directory $APPDIR DOES NOT exists." && exit 1
echo 'Updating app please wait...'
generate_deps $APPDIR
cd ~
echo 'Update complete!'
start
}

start
