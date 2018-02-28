#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or sudo" 1>&2
   exit 1
fi
echo Nginx Installation and setup...
echo
echo '==============WARNING================='
echo
echo 'This script will remove your existing postgresql installation'
echo 'and all postgresql databases, users and user data. This script will install'
echo 'Nginx'
echo
echo '======================================'
echo
echo 'Press enter to continue or Ctrl+c to cancel'
read usercontinue
clear

apt-get update
apt-get install -y nginx

echo Successfully installed nginx

echo Setup your website
echo Site url: 
read siteurl
echo Site root folder
read sitedir

echo Creating Nginx site configuration
cat << EOF > /etc/nginx/sites-available/$siteurl
server {
        listen   80;

        root $sitedir;
        index index.php index.html index.htm;

        server_name www.$siteurl $siteurl;
        location / {
        try_files \$uri \$uri/ /index.html;
        }

        location ~ /\\.ht {
                deny all;
        }
}
EOF

ln -s /etc/nginx/sites-available/$siteurl /etc/nginx/sites-enabled/

service nginx restart

echo You can now view your site on $siteurl
echo You can view/edit/delete your site configuration at /etc/nginx/sites-available/$siteurl
