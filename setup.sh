#!/bin/sh

if [[ "$APP_ENV" == "dev" ]]
    then
        cp web/sites/example.settings.local.php web/sites/default/settings.local.php
        COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev
        # yarn install && node_modules/.bin/gulp sass
        chown -R apache:apache web/sites web/modules web/themes
        if !(drush status bootstrap | grep -iq successful)
            then
                drush site-install --verbose config_installer --yes && drush upwd admin P@ssw0rd
                drush cr && drush config:import && drush updb && drush cr
            fi
    fi

if [[ "$APP_ENV" == "prod" ]]
	  then
		    cp web/sites/default/sourcerider.settings.php web/sites/default/settings.php

		    /usr/sbin/php-fpm
		    /usr/sbin/httpd -DFOREGROUND
	  fi

if [[ "$APP_ENV" == "shell" ]]
	  then
		    cp web/sites/default/sourcerider.settings.php web/sites/default/settings.php
		    drush cron
	  fi
