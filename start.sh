#!/bin/bash
set -e

WP_DB_HOST=${WP_DB_HOST:-localhost}
WP_DB_NAME=${WP_DB_NAME:-wordpress}
WP_DB_USERNAME=${WP_DB_USERNAME:-wordpress}
# WP_VERSION=${$WP_VERSION:-4.2.2}
WP_DB_PASSWORD=${WP_DB_PASSWORD:-`pwgen -c -n -1 12`}
WP_PASSWORD=${WP_PASSWORD:-`pwgen -c -n -1 12`}

if [ "$WP_DB_HOST"x -eq  "localhost"x ] ; then
    exit -1
fi


chmod 777 -R /usr/share/nginx/html
mv /usr/share/nginx/wordpress/* /usr/share/nginx/html/
chown -R www-data:www-data /usr/share/nginx/html

if [ ! -f /usr/share/nginx/html/wp-config.php ]; then
  #mysql has to be started this way as it doesn't work to call from /etc/init.d

  # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
  #This is so the passwords show up in logs. 
  echo mysql root password: $WP_DB_PASSWORD
  echo wordpress password: $WP_PASSWORD
  echo $WP_DB_PASSWORD > /mysql-root-pw.txt
  echo $WP_PASSWORD > /wordpress-db-pw.txt

  sed -e "s/database_name_here/$WP_DB_USERNAME/
  s/DB_HOST/$WP_DB_HOST/
  s/username_here/$WP_DB_USERNAME/
  s/password_here/$WP_DB_PASSWORD/
  /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/html/wp-config-sample.php > /usr/share/nginx/html/wp-config.php

  # Download nginx helper plugin
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip nginx-helper.*.zip -d /usr/share/nginx/html/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/html/wp-content/plugins/nginx-helper

  # Activate nginx plugin and set up pretty permalink structure once logged in
  cat << ENDL >> /usr/share/nginx/html/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$wp_rewrite->set_permalink_structure( '/%postname%/' );
  \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php' );
  foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/share/nginx/html/wp-content/plugins/' . \$plugin );
    }
  }
}
ENDL
  chown www-data:www-data /usr/share/nginx/html/wp-config.php

fi

# start all the services
exec sh /assets/init
