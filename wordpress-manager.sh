#!/bin/bash

# Require script to be run as root (or with sudo)
function super-user-check() {
    if [ "$EUID" -ne 0 ]; then
        echo "You need to run this script as super user."
        exit
    fi
}

# Check for root
super-user-check

# Pre-Checks
function check-system-requirements() {
    # System requirements (uname)
    if ! [ -x "$(command -v uname)" ]; then
        echo "Error: uname  is not installed, please install uname." >&2
        exit
    fi
    # System requirements (curl)
    if ! [ -x "$(command -v curl)" ]; then
        echo "Error: curl  is not installed, please install curl." >&2
        exit
    fi
    # System requirements (jq)
    if ! [ -x "$(command -v jq)" ]; then
        echo "Error: jq  is not installed, please install jq." >&2
        exit
    fi
    # System requirements (openssl)
    if ! [ -x "$(command -v openssl)" ]; then
        echo "Error: openssl  is not installed, please install openssl." >&2
        exit
    fi
}

# Run the function and check for requirements
check-system-requirements

# Detect Operating System
function dist-check() {
    # shellcheck disable=SC1090
    if [ -e /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO=$ID
    fi
}

# Check Operating System
dist-check

if [ ! -f "/var/www/wp-config.php" ]; then

# Install Wordpress Server
function install-wordpress() {
    # Installation begins here
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]); then
        apt-get update
        apt-get install nginx curl redis-server zip unzip php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis certbot python-certbot-nginx -y
    fi
    if [ "$DISTRO" == "arch" ]; then
        pacman -Syu
        pacman -Syu --noconfirm nginx curl redis-server zip unzip php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis certbot certbot-nginx
    fi
    if ([ "$DISTRO" == "centos" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "rhel" ]); then
        yum update -y
        yum install nginx curl redis-server zip unzip php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis certbot certbot-nginx -y
    fi
}

    # Install Wordpress Server
    install-wordpress

    # Configure Wordpress
function configure-wordpress() {
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
        rm -f /var/www/html/index.nginx-debian.html
        curl https://wordpress.org/latest.tar.gz -o /tmp/latest.tar.gz
        tar xf /tmp/latest.tar.gz
        mv /tmp/wordpress/* /var/www/html
        rm /tmp/latest.tar.gz
        rm -rf /tmp/wordpress
        chown www-data:www-data -R *
        find /var/www/ -type d -exec chmod 755 {} \;
        find /var/www/ -type f -exec chmod 644 {} \;
        chmod 660 wp-config.php
        chown -R www-data:www-data /var/www/html
    fi
}

# configure Wordpress
configure-wordpress

# configure Redis
function configure-redis() {
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
        sed -i "s|# bind 127.0.0.1;|bind 127.0.0.1;|" /etc/redis/redis.conf
        curl https://downloads.wordpress.org/plugin/redis-cache.1.5.8.zip --create-dirs -o /var/www/html/wp-content/plugins/redis-cache.1.5.8.zip
        unzip /var/www/html/wp-content/plugins/redis-cache.1.5.8.zip
        rm -f /var/www/html/wp-content/plugins/redis-cache.1.5.8.zip
    fi
    if pgrep systemd-journal; then
        systemctl enable redis
        systemctl restart redis
    else
        service redis enable
        service redis restart
    fi
}

# Configure Redis
configure-redis

# Configure Nginx
function configure-nginx() {
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
        sed -i "s|# server_tokens off;|server_tokens off;|" /etc/nginx/nginx.conf
        rm -f /etc/nginx/sites-available/default
        echo "server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.php;
    server_name _;
    location / {
      try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
      include snippets/fastcgi-php.conf;
      fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    }
}" >>/etc/nginx/sites-available/default
    fi
    if pgrep systemd-journal; then
        systemctl enable nginx
        systemctl restart nginx
    else
        service nginx enable
        service nginx restart
    fi
}

# nginx
configure-nginx

## Function to install mysql
function mysql-install() {
        MARIADB_DATABASE="$(openssl rand -base64 15)"
        MARIADB_USER="$(openssl rand -base64 15)"
        MARIADB_PASSWORD="$(openssl rand -base64 20)"
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]); then
        apt-get install mariadb-server -y
    fi
    if [ "$DISTRO" == "arch" ]; then
        pacman -Syu --noconfirm mariadb
    fi
    if ([ "$DISTRO" == "centos" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "rhel" ]); then
        yum install mariadb -y
    fi
        # https://cloud.google.com/sql/docs/mysql/connect-external-app
        mysql_secure_installation
        mariadb
        CREATE DATABASE $MARIADB_DATABASE;
        CREATE USER $($MARIADB_USER)@$(localhost) IDENTIFIED BY '$MARIADB_PASSWORD';
        ALTER USER $($MARIADB_USER)@$(localhost) IDENTIFIED WITH mysql_native_password BY '$MARIADB_PASSWORD';
        GRANT ALL ON $MARIADB_DATABASE.* TO $($MARIADB_USER)@$(localhost);
        FLUSH PRIVILEGES;
        exit
}

## run the function
mysql-install

function configure-php() {
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
        sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 32M|" /etc/php/7.3/fpm/php.ini
        sed -i "s|max_file_uploads = 20|max_file_uploads = 25|" /etc/php/7.3/fpm/php.ini
    fi
    if pgrep systemd-journal; then
        systemctl enable php7.3-fpm
        systemctl restart php7.3-fpm
    else
        service php7.3-fpm enable
        service php7.3-fpm restart
    fi
}

    configure-php

    # wp-cli
function wp-cli() {
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
        curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar --create-dirs -o /usr/local/bin/wp/wp-cli.phar
        chmod +x /usr/local/bin/wp/wp-cli.phar
        php /usr/local/bin/wp/wp-cli.phar --info
    fi
}

    # Install WP-CLI
    wp-cli

function wp-config() {
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
        mv /var/www/html/wp-config-sample.php /var/www/wp-config.php
        sed -i "s|database_name_here|$MARIADB_DATABASE|" /var/www/wp-config.php
        sed -i "s|username_here|$MARIADB_USER|" /var/www/wp-config.php
        sed -i "s|password_here|$MARIADB_PASSWORD|" /var/www/wp-config.php
    fi
        echo "/* Media Trash. */
define( 'MEDIA_TRASH', true );

/* Multisite. */
define( 'WP_ALLOW_MULTISITE', false );

/* WordPress debug mode for developers. */
define( 'WP_DEBUG',         true );
define( 'WP_DEBUG_LOG',     true );
define( 'WP_DEBUG_DISPLAY', true );
define( 'SCRIPT_DEBUG',     true );
define( 'SAVEQUERIES',      true );

/* WordPress Cache */
define( 'WP_CACHE', true );

/* Compression */
define( 'COMPRESS_CSS',        true );
define( 'COMPRESS_SCRIPTS',    true );
define( 'CONCATENATE_SCRIPTS', true );
define( 'ENFORCE_GZIP',        true );

/* FTP */
define( 'FTP_SSL', true );

/* CRON */
define( 'DISABLE_WP_CRON',      'true' );
define( 'ALTERNATE_WP_CRON',    'true' );

/* Updates */
define( 'WP_AUTO_UPDATE_CORE', 'minor' );
define( 'DISALLOW_FILE_MODS', false );
define( 'DISALLOW_FILE_EDIT', false );" >>/var/www/wp-config.php
    }

wp-config

function minify-output() {
echo "/* Remove Query String */
function _remove_script_version( $src ){
    $parts = explode( '?ver', $src );
    return $parts[0];
}

add_filter( 'script_loader_src', '_remove_script_version', 15, 1 );
add_filter( 'style_loader_src', '_remove_script_version', 15, 1 );

/* Minify HTML */
add_action('get_header', 'gkp_html_minify_start');
function gkp_html_minify_start()
{
    ob_start('gkp_html_minyfy_finish');
}
function gkp_html_minyfy_finish($html)
{
    $html = preg_replace('/<!--(?!s*(?:[if [^]]+]|!|>))(?:(?!-->).)*-->/s', '', $html);
    $html = str_replace(array(
        "\r\n",
        "\r",
        "\n",
        "\t"
    ), '', $html);
    while (stristr($html, '  '))
        $html = str_replace('  ', ' ', $html);
    return $html;
}" >> /var/www/html/wp-content/themes/function.php
# end of function
}

# Installs and setups lets-encrypt
function lets-encrypt() {
    certbot --nginx
    certbot renew --dry-run
}

# lets-encrypt function
lets-encrypt

function install-bbr() {
        # Check if tcp brr can be installed and if yes than install
        KERNEL_VERSION_LIMIT=4.1
        KERNEL_CURRENT_VERSION=$(uname -r | cut -c1-3)
    if (($(echo "$KERNEL_CURRENT_VERSION >= $KERNEL_VERSION_LIMIT" | bc -l))); then
        modprobe tcp_bbr
        echo "tcp_bbr" >>/etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >>/etc/sysctl.d/shadowsocks.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.d/shadowsocks.conf
        sysctl -p
    else
        echo "Error: Please update your kernel to 4.1 or higher" >&2
    fi
    }

# Install TCP BBR
install-bbr

# After wordpress Install
else

# Already installed what next?
function wordpress-next-questions() {
    echo "What do you want to do?"
    echo "   1) Start WordPress"
    echo "   2) Stop WordPress"
    echo "   3) Restart WordPress"
    echo "   4) Uninstall WordPress"
    echo "   5) Update this script"
    until [[ "$WORDPRESS_OPTIONS" =~ ^[1-6]$ ]]; do
    read -rp "Select an Option [1-6]: " -e -i 1 WORDPRESS_OPTIONS
    done
    case $WORDPRESS_OPTIONS in
    1)
    if pgrep systemd-journal; then
        systemctl enable nginx
        systemctl restart nginx
        systemctl enable php7.3-fpm
        systemctl restart php7.3-fpm
    else
        service nginx enable
        service nginx restart
        service php7.3-fpm enable
        service php7.3-fpm restart
    fi
    ;;
    2)
    if pgrep systemd-journal; then
        systemctl stop nginx
        systemctl stop php7.3-fpm
    else
        service nginx stop
        service php7.3-fpm stop
    fi
    ;;
    3)
    if pgrep systemd-journal; then
        systemctl restart nginx
        systemctl restart php7.3-fpm
    else
        service nginx restart
        service php7.3-fpm restart
    fi
    ;;
    4)
    if pgrep systemd-journal; then
        systemctl disable nginx
        systemctl stop nginx
        systemctl disable php7.3-fpm
        systemctl stop php7.3-fpm
    else
        nginx disable
        nginx stop
        php7.3-fpm disable
        php7.3-fpm stop
    fi
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]); then
        apt-get remove --purge nginx curl redis-server zip unzip php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis certbot python-certbot-nginx -y
    fi
    if [ "$DISTRO" == "arch" ]; then
        pacman -Rs nginx curl redis-server zip unzip php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis
    fi
    if ([ "$DISTRO" == "centos" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "rhel" ]); then
        yum remove --purge nginx curl redis-server zip unzip php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis -y
    fi
        rm -f /usr/local/bin/wp/wp-cli.phar
        rm -f /etc/nginx/sites-available/default
        rm -f /etc/nginx/nginx.conf
        rm -f /var/www/wp-config.php
        rm -f /var/www/wordpress-manager.sh
        rm -rf /etc/nginx
        rm -rf /var/www/html
    ;;
    5) # Update the script
        curl -o /var/www/wordpress-manager.sh https://raw.githubusercontent.com/complexorganizations/wordpress-manager/main/wordpress-manager.sh
        chmod +x /var/www/wordpress-manager.sh || exit
    ;;
    esac
}

# Questions
wordpress-next-questions

fi
