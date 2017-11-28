#!/bin/bash locale
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#config
PROD_DIR="directory_name"
DEV_DIR="dev_directory_name"
ADMIN_DIR="admin_directory_name"
WORKING_DIR="/var/www/"
#to add a cidr range, do so in the following format: 0.0.0.0\/0 using the \ to escape
IP_WHITELIST0="00.00.00.00"
IP_WHITELIST1="00.00.00.00"
IP_WHITELIST2="00.00.00.00"
IP_WHITELIST3="00.00.00.00"
IP_WHITELIST4="00.00.00.00"
IP_WHITELIST5="00.00.00.00"
IP_WHITELIST6="00.00.00.00"

#database config
DEV_USER="dev_database_username"
DEV_PW="dev_database_password"
DEV_DB="dev_database"

PROD_USER="prod_database_username"
PROD_PW="prod_database_password"
PROD_DB="prod_database"

# no customization needed below this line, unless you want to snip the ip filters

#get to the working directory
	echo "  Move into the working directory..."
	cd $WORKING_DIR

#remove any previous backup (if exists)
	if [ -d bak.$PROD_DIR ]; then rm -Rf bak.$PROD_DIR; fi

#backup existing prod
	echo "  Making a backup of existing prod dir..."
	mv $PROD_DIR bak.$PROD_DIR

#merge dev to prod
	echo "  Merging dev and prod..."
	cp -a $DEV_DIR -R $PROD_DIR

#update config paths
	echo "  Updating config paths..."
	cd $PROD_DIR

	#.git dir is copied from the dev site, we don't need it in our testing directory
	if [ -d .git ]; then rm -Rf .git; fi

		#update the whitelist
		sed -i "s/Require ip $IP_WHITELIST0/Require ip $IP_WHITELIST0\nRequire ip $IP_WHITELIST1\nRequire ip $IP_WHITELIST2\nRequire ip $IP_WHITELIST3\nRequire ip $IP_WHITELIST4\nRequire ip $IP_WHITELIST5\nRequire ip $IP_WHITELIST6/g" .htaccess
		#native bash replace may be better than sed.. but this works, so why not.  decided against recursive; too many folders for so few replacements
		sed -i "s/$DEV_DIR/$PROD_DIR/g" config.php .htaccess
		sed -i "s/$DEV_USER/$PROD_USER/g" config.php #tip: this gets jacked up if user & db name are the same
		sed -i "s/$DEV_PW/$PROD_PW/g" config.php
		sed -i "s/$DEV_DB/$PROD_DB/g" config.php

	#now the admin
	cd "$ADMIN_DIR"
		sed -i "s/$DEV_DIR/$PROD_DIR/g" config.php
		sed -i "s/$DEV_USER/$PROD_USER/g" config.php
		sed -i "s/$DEV_PW/$PROD_PW/g" config.php
		sed -i "s/$DEV_DB/$PROD_DB/g" config.php
	echo "  Config paths updated..."

	#purge the prod db
	echo "  Purging production database..."
	mysqldump -u"$PROD_USER" -p"$PROD_PW" --add-drop-table --no-data "$PROD_DB" | grep ^DROP | mysql -u"$PROD_USER" -p"$PROD_PW" "$PROD_DB"

	#clone the db
	echo "  Cloning development database..."
	mysqldump "$DEV_DB" -u "$DEV_USER" -p"$DEV_PW" | mysql "$PROD_DB" -u"$PROD_USER" -p"$PROD_PW"

	echo "  DONE!"
