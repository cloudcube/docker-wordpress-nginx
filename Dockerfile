FROM cloudcube/base
MAINTAINER DavidZhao <zhaohaibin@outlook.com>
ENV REFRESHED_AT 2015-07-20 10:15

RUN apt-get update
RUN apt-get -y upgrade

# Keep upstart from complaining
# Basic Requirements
RUN apt-get -y install mysql-client nginx php5-fpm php5-mysql php-apc pwgen python-setuptools curl git unzip

# Wordpress Requirements
RUN apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# nginx site conf
ADD ./config/nginx-site.conf /etc/nginx/sites-available/default
ADD ./config/nginxd.conf /etc/supervisor/conf.d/nginxd.conf
ADD ./config/php5-fpmd.conf /etc/supervisor/conf.d/php5-fpmd.conf

# Install Wordpress
ADD https://cn.wordpress.org/wordpress-4.2.2-zh_CN.tar.gz /wordpress.tar.gz
RUN tar xvzf /wordpress.tar.gz -C /usr/share/nginx
RUN mv /usr/share/nginx/html/5* /usr/share/nginx/wordpress
RUN rm -rf /usr/share/nginx/html

# RUN mv /usr/share/nginx/wordpress /usr/share/nginx/html
# RUN chown -R www-data:www-data /usr/share/nginx/html



# Wordpress Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

# private expose
EXPOSE 80
EXPOSE 22


VOLUME ["/usr/share/nginx/html"]

CMD ["/bin/bash", "/start.sh"]
