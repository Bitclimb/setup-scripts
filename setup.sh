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
   echo "This script is not intended to be ran as root/sudo" 1>&2
   exit 1
fi

clear
echo Nvm, Node, Npm and Pm2 Installation and setup...
echo
echo 'Press enter to continue or Ctrl+c to cancel'
read usercontinue
echo

echo Installing NVM
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
echo "You are now using Nvm $(nvm --version)"

echo Installing Nodejs LTS and NPM
nvm install --lts --latest-npm
echo "You are now using Node $(node -v) and Npm $(npm -v)"

echo Installing Pm2
npm install pm2 -g
echo "You are now using Pm2 $(pm2 -v)"

echo Installation complete!
