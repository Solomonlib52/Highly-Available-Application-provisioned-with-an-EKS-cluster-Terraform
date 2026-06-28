FROM drupal:10-php8.3-apache

# 1. Install runtime tools and enable Apache modules
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod rewrite headers

# 2. Configure php.ini from production template
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/php.ini \
    && echo "upload_max_filesize = 64M" >> /usr/local/etc/php/php.ini \
    && echo "post_max_size = 64M" >> /usr/local/etc/php/php.ini \
    && echo "max_execution_time = 600" >> /usr/local/etc/php/php.ini \
    && echo "error_reporting = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED" >> /usr/local/etc/php/php.ini

# 3. Files directory
RUN mkdir -p /var/www/html/sites/default/files \
    && chown -R www-data:www-data /var/www/html/sites/default/files

# 4. Copy settings.php (DB credentials come from env in Docker Compose/Kubernetes)
COPY settings.php /var/www/html/sites/default/settings.php
RUN chown www-data:www-data /var/www/html/sites/default/settings.php \
    && chmod 640 /var/www/html/sites/default/settings.php

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fsS http://localhost/core/misc/drupal.js >/dev/null || exit 1
