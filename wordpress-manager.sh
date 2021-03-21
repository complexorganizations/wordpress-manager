#!/bin/bash
# https://github.com/complexorganizations/wordpress-manager

# Require script to be run as root
function super-user-check() {
  if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as super user."
    exit
  fi
}

# Check for root
super-user-check

# Detect Operating System
function dist-check() {
  if [ -e /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO=${ID}
  fi
}

# Check Operating System
dist-check

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ]; }; then
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v bc)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v sed)" ] || [ ! -x "$(command -v zip)" ] || [ ! -x "$(command -v unzip)" ] || [ ! -x "$(command -v grep)" ] || [ ! -x "$(command -v awk)" ]; }; then
      if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ]; }; then
        apt-get update && apt-get install curl coreutils bc jq sed e2fsprogs zip unzip grep gawk iproute2 -y
      elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
        yum update -y && yum install epel-release curl coreutils bc jq sed e2fsprogs zip unzip grep gawk iproute2 -y
      elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ]; }; then
        pacman -Syu --noconfirm curl bc jq sed zip unzip grep gawk iproute2
      elif [ "${DISTRO}" == "alpine" ]; then
        apk update && apk add curl bc jq sed zip unzip grep gawk iproute2
      fi
    fi
  else
    echo "Error: ${DISTRO} not supported."
    exit
  fi
}

WPCONFIG="/var/www/wp-config.php"
WORDPRESS_DOWNLOAD_URL="https://wordpress.org/latest.tar.gz"
REDIS_PLUGIN_URL="https://downloads.wordpress.org/plugin/redis-cache.2.0.17.zip"
REDIS_PLUGIN_PATH="/var/www/html/wp-content/plugins/redis-cache.2.0.17.zip"
NGINX_SITE_DEFAULT_CONFIG="/etc/nginx/sites-available/default"
NGINX_GLOBAL_DEFAULT_CONFIG="/etc/nginx/nginx.conf"
WP_CLI_UPDATE_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
WP_CLI_CONFIG_PATH="/usr/local/bin/wp/wp-cli.phar"
WORDPRESS_MANAGER_URL="https://raw.githubusercontent.com/complexorganizations/wordpress-manager/main/wordpress-manager.sh"
REDIS_CONFIG_PATH="/etc/redis/redis.conf"

if [ ! -f "${WPCONFIG}" ]; then

  # Install Wordpress Server
  function install-wordpress() {
    # Installation begins here
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ]; }; then
      apt-get update
      apt-get install nginx curl redis-server zip unzip php7.4-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis -y
    elif [ "${DISTRO}" == "arch" ]; then
      pacman -Syu
      pacman -Syu --noconfirm nginx curl redis-server zip unzip php7.4-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis
    elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
      yum update -y
      yum install nginx curl redis-server zip unzip php7.4-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis -y
    fi
  }

  # Install Wordpress Server
  install-wordpress

  # Configure Wordpress
  function configure-wordpress() {
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ]; }; then
      curl ${WORDPRESS_DOWNLOAD_URL} -o /tmp/latest.tar.gz
      tar xf /tmp/latest.tar.gz -C /tmp/
      mv /tmp/wordpress/* /var/www/html
      rm /tmp/latest.tar.gz
      rm -rf /tmp/wordpress
      # chown www-data:www-data -R *
      find /var/www/ -type d -exec chmod 755 {} \;
      find /var/www/ -type f -exec chmod 644 {} \;
      chown -R www-data:www-data /var/www/html
    fi
  }

  # configure Wordpress
  configure-wordpress

  # configure Redis
  function configure-redis() {
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ]; }; then
      sed -i "s|# bind 127.0.0.1;|bind 127.0.0.1;|" ${REDIS_CONFIG_PATH}
      curl ${REDIS_PLUGIN_URL} --create-dirs -o ${REDIS_PLUGIN_PATH}
      unzip ${REDIS_PLUGIN_PATH}
      rm -f ${REDIS_PLUGIN_PATH}
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
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ]; }; then
      rm -f /var/www/html/index.nginx-debian.html
      sed -i "s|# server_tokens off;|server_tokens off;|" ${NGINX_GLOBAL_DEFAULT_CONFIG}
      rm -f ${NGINX_SITE_DEFAULT_CONFIG}
      # shellcheck disable=SC2154,SC2154
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
      fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }
}" >>${NGINX_SITE_DEFAULT_CONFIG}
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
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ]; }; then
      apt-get install mariadb-server -y
    elif [ "${DISTRO}" == "arch" ]; then
      pacman -Syu --noconfirm mariadb
    elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
      yum install mariadb -y
    fi
    # https://cloud.google.com/sql/docs/mysql/connect-external-app
    printf "n\n n\n y\n y\n y\n y\n" | mysql_secure_installation
    mariadb -e "CREATE DATABASE \"${MARIADB_DATABASE}\";"
    mariadb -e "CREATE USER \"${MARIADB_USER}\"@localhost IDENTIFIED BY \"${MARIADB_PASSWORD}\";"
    mariadb -e "ALTER USER \"${MARIADB_USER}\"@localhost IDENTIFIED WITH mysql_native_password BY \"${MARIADB_PASSWORD}\";"
    mariadb -e "GRANT ALL ON \"${MARIADB_DATABASE}\".* TO \"${MARIADB_USER}\"@localhost;"
    echo "Database: ${MARIADB_DATABASE}"
    echo "Username: ${MARIADB_USER}"
    echo "Password: ${MARIADB_PASSWORD}"
  }

  ## run the function
  mysql-install

  # wp-cli
  function wp-cli() {
    if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ]; }; then
      curl $WP_CLI_UPDATE_URL --create-dirs -o ${WP_CLI_CONFIG_PATH}
      chmod +x ${WP_CLI_CONFIG_PATH}
      php ${WP_CLI_CONFIG_PATH} --info
    fi
  }

  # Install WP-CLI
  wp-cli

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
    until [[ "${WORDPRESS_OPTIONS}" =~ ^[1-6]$ ]]; do
      read -rp "Select an Option [1-6]: " -e -i 1 WORDPRESS_OPTIONS
    done
    case ${WORDPRESS_OPTIONS} in
    1)
      if pgrep systemd-journal; then
        systemctl enable nginx
        systemctl restart nginx
        systemctl enable php7.4-fpm
        systemctl restart php7.4-fpm
      else
        service nginx enable
        service nginx restart
        service php7.4-fpm enable
        service php7.4-fpm restart
      fi
      ;;
    2)
      if pgrep systemd-journal; then
        systemctl stop nginx
        systemctl stop php7.4-fpm
      else
        service nginx stop
        service php7.4-fpm stop
      fi
      ;;
    3)
      if pgrep systemd-journal; then
        systemctl restart nginx
        systemctl restart php7.4-fpm
      else
        service nginx restart
        service php7.4-fpm restart
      fi
      ;;
    4)
      if pgrep systemd-journal; then
        systemctl disable nginx
        systemctl stop nginx
        systemctl disable php7.4-fpm
        systemctl stop php7.4-fpm
      else
        nginx disable
        nginx stop
        php7.4-fpm disable
        php7.4-fpm stop
      fi
      if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ]; }; then
        apt-get remove --purge nginx curl redis-server zip unzip php7.4-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis -y
      elif [ "${DISTRO}" == "arch" ]; then
        pacman -Rs nginx curl redis-server zip unzip php7.4-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis
      elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
        yum remove --purge nginx curl redis-server zip unzip php7.4-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis -y
      fi
      rm -f ${WP_CLI_CONFIG_PATH}
      rm -f ${NGINX_SITE_DEFAULT_CONFIG}
      rm -f ${NGINX_GLOBAL_DEFAULT_CONFIG}
      rm -f ${NGINX_SITE_DEFAULT_CONFIG}
      rm -f ${WPCONFIG}
      ;;
    5) # Update the script
      CURRENT_FILE_PATH="$(realpath "$0")"
      if [ -f "${CURRENT_FILE_PATH}" ]; then
        curl -o "${CURRENT_FILE_PATH}" ${WORDPRESS_MANAGER_URL}
        chmod +x "${CURRENT_FILE_PATH}" || exit
      fi
      ;;
    esac
  }

  # Questions
  wordpress-next-questions

fi
