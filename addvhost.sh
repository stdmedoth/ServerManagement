#!/usr/bin/env bash
#
# Nginx - new server block
# http://rosehosting.com
read -p "Enter domain name : " domain

# Functions
ok() { echo -e '\e[32m'$domain'\e[m'; } # Green
die() { echo -e '\e[1;31m'$domain'\e[m'; exit 1; }

# Variables
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
#[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$domain.conf <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $domain;

    rewrite ^ https://$domain\$request_uri? permanent;
}

server {
    listen 443 ssl http2;

    ssl_certificate /etc/ssl/certs/cardban.com.br.crt;
    ssl_certificate_key /etc/ssl/certs/cardban.com.br.key;
    ssl_stapling on;

    root /var/www/$domain/public_html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name $domain;

    access_log /var/www/$domain/logs/access.log;
    error_log  /var/www/$domain/logs/error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        #include snippets/fastcgi-php.conf;

        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}

EOF

cp $NGINX_AVAILABLE_VHOSTS/$domain.conf $NGINX_ENABLED_VHOSTS/$domain.conf

# Creating {public,log} directories
mkdir -p $WEB_DIR/$domain/{public_html,logs}

# Creating index.html file
cat > $WEB_DIR/$domain/public_html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
      	<title>$domain</title>
        <meta charset="utf-8" />
</head>
<body class="container">
        <header><h1>$domain<h1></header>
        <div id="wrapper"><p>Hello World</p></div>
        <footer>© $(date +%Y)</footer>
</body>
</html>
EOF

# Changing permissions
chown -R nginx:nginx $WEB_DIR/$domain

# Enable site by creating symbolic link
# ln -s $NGINX_AVAILABLE_VHOSTS/$1 $NGINX_ENABLED_VHOSTS/$1

# Restart
echo "Do you wish to restart nginx?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) service nginx restart ; break;;
        No ) exit;;
    esac
done

ok "Site Created for $domain"


