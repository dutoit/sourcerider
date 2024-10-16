FROM amazonlinux:2 as base
ARG app_env
RUN yum update -y && yum install -y mysql wget zip
RUN if [ "$app_env" = "dev" ]; then yum install -y vim; fi

# Install PHP 8.2
RUN amazon-linux-extras enable php8.2
RUN yum install -y php php-cli php-devel php-pdo php-mbstring php-pear php-dom \
                   php-gd php-xml php-mbstring.x86_64 php-opcache php-pecl-memcached \
                   && yum clean all && rm -rf /var/cache/yum

# Composer installation
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

# Install Node.js
RUN curl --silent --location https://rpm.nodesource.com/setup_18.x | bash - && \
    yum install -y nodejs && \
    yum clean all && rm -rf /var/cache/yum

# Install global npm packages
RUN npm install --global yarn gulp-cli

# Configure Apache and PHP settings
COPY apache-drupal.conf /etc/httpd/conf.d/vhosts.conf
COPY apache-log.conf /etc/httpd/conf.d/logs.conf
COPY apache-mpm.conf /etc/httpd/conf.modules.d/00-mpm.conf
COPY php.ini /etc
COPY php-fpm-www.conf /etc/php-fpm.d/www.conf

# Configure logging
RUN ln -sf /proc/1/fd/1 /var/log/httpd/access_log && \
    ln -sf /proc/1/fd/2 /var/log/httpd/error_log && \
    ln -sf /proc/1/fd/2 /var/log/php-fpm/error.log

WORKDIR /var/www/html
COPY ./setup.sh /
RUN chmod +x /setup.sh
ENV PATH "$PATH:/var/www/html/vendor/bin"
ENTRYPOINT ["/setup.sh"]

# Production stage
FROM base as prod
COPY src /var/www/html/
RUN set -eux; \
    COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev; \
    yarn install; \
    gulp --production; \
    chown -R apache:apache web/sites web/modules web/themes
RUN mkdir -p /var/log/containers
