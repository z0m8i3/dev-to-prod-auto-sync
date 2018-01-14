#!/bin/bash

## note!
# although not required, it is ideal to run this script in a level above public/www; inaccessible to the outside world
# a .cnf file with your credentials will be created; this script will chmod it for user-specific permissions & also adds the .ht prefix; so atleast in apache environments, is blocked to the outside world by default
# if this script is being ran in a publicly accessible directory, you should also make attempts to access the .htmergedev.cnf file without required permission, to ensure it is not served
# ideally, do not use your "root" db user; but a dedicated user specifically for backups with only the permissions on the db(s) it requires
# only tested with db instances on the same host; may be doable for remote syncing, but untested
# full source available at: https://github.com/z0m8i3 under the GPLv3 license

# bash check
if [ ! "$BASH_VERSION" ];
	then
		echo "Run this script directly; with ./$0, rather than \"sh $0\""
		exit 0
fi

# make sure we're not in commonly insecure directories for this type of script
if [[ $PWD == '/var/www/' || $PWD == '/var/www/html/' || $PWD == '/var/www/public_html/' ]];
	then
		echo "Please move this script into a NON public directory!"
		exit 0
fi

CONF_FILE=".htmergedev.cnf"

# check if this is first run by existence of the cnf file; if not, execute the script
if [ -f $CONF_FILE ];
	then
		#make sure the permissions are secure
		if [ -x $CONF_FILE ];
			then
				echo ".htmergedev.cnf is executable. Please inspect and fix the permissions.  Exiting..."
				exit 0
			fi

		# parse the contents of the config
		source .htmergedev.cnf

		# before we get to business, make sure what we need even exists
		if [ ! -d $SOURCE_DIR ];
			then
				echo "$SOURCE_DIR does not exist, or has been moved; exiting... (re-create the directory to proceed)"
				exit 0
		elif [ ! -d $DESTINATION_DIR ];
			then
				echo "$DESTINATION_DIR does not exist, or has been moved; exiting... (re-create the directory to proceed)"
				exit 0
		fi

		# proceed...
		echo "  Moving into $SOURCE_DIR"
		cd $SOURCE_DIR

			# merge source -> desintation files
			echo "  Merging $SOURCE_DIR and $DESTINATION_DIR..."
			cp -au $SOURCE_DIR $DESTINATION_DIR

			# move into destination directory
			cd $DESTINATION_DIR

			# .git dir is copied from the destination site, we don't need it in our production/testing directory
			if [ -d .git ]; then rm -Rf .git; fi

			# native bash replace may be better than sed.. but this works, so why not.  decided against recursive; too many folders for so few replacements
			# first, make sure both config & .htaccess exist
			if [[ -f "$DESTINATION_DIR"config.php && -f "$DESTINATION_DIR".htaccess ]];
				then
					sed -i "s/$DEV_DIR/$DESTINATION_DIR/g" config.php .htaccess
			fi

			if [[ -f "$DESTINATION_DIR"config.php ]];
				then
					# update config paths
					echo "  Updating config paths..."
					sed -i "s/$DEV_USER/$PROD_USER/g" config.php #tip: this gets jacked up if user & db name are the same
					sed -i "s/$DEV_PW/$PROD_PW/g" config.php
					sed -i "s/$DEV_DB/$PROD_DB/g" config.php
				else
					echo ">! config.php not detected - skipping..."
				fi

			# now the admin
			if [[ -d $ADMIN_DIR ]];
				then
					cd "$ADMIN_DIR"
						sed -i "s/$DEV_DIR/$DESTINATION_DIR/g" config.php
						sed -i "s/$DEV_USER/$PROD_USER/g" config.php
						sed -i "s/$DEV_PW/$PROD_PW/g" config.php
						sed -i "s/$DEV_DB/$PROD_DB/g" config.php
					echo "  Config paths updated..."
				else
					echo ">! $ADMIN_DIR not detected - skipping..."
			fi

			# this script won't test your connection or verify its work; do your due dilligance & ensure everything executed smoothly before you trust this script to automate regulaly for you

			# purge the destination db & prepare it for syncing with the source db
			echo "  Purging destination database..."
			mysqldump -u $DEST_DB_USR -p$DEST_DB_PWD --add-drop-table --no-data $DEST_DB | grep ^DROP | mysql -u $DEST_DB_USR -p$DEST_DB_PWD $DEST_DB -h $SOURCE_HOST

			# clone the source db
			echo "  Cloning development database..."
			mysqldump -u$SOURCE_DB_USR -p$SOURCE_DB_PWD --routines $SOURCE_DB -h$SOURCE_HOST | mysql -u$DEST_DB_USR -p$DEST_DB_PWD -A $DEST_DB -h$DEST_HOST

			echo "  DONE!"

	# first run; prompt for config setup
	elif [[ ! -f $CONF_FILE ]];
		then

		# start with a clean terminal
		clear

		# welcome !
		echo -e "This script will create a config file in $PWD with credentials provided by you, in the following prompts.\n"
		echo -e "It will NOT validate/check your answers, if you mess up, just delete the .cnf file it creates and re-run this script."
		echo -e ">> Press enter to continue. <<"

		# validate user is paying attention
		read confirm

		# create a hidden file for config on first run
		touch .htmergedev.cnf
		# assign owner-only access
		chmod 600 .htmergedev.cnf

		echo -e "\n############################\n"

		# gather vars and write to cnf file
		echo -e "When prompted for a path/destination, use the absolute path: /var/www/your/path/ -- SPECIFYING SLASHES!\n"
		echo -e "\n\nSource directory location:"
		read SOURCE_DIR
		echo "SOURCE_DIR=$SOURCE_DIR" >> $CONF_FILE

		# check for potentially fatal typos (the only validation we're doing..)
		if [[ $SOURCE_DIR == "/" ]];
			then
				echo "Assuming / is a typo.."
				echo "Re-run this script and try again.  Exiting.."
				rm .mergedev.cnf
				exit 0
		fi

		echo -e "\n\nAnd the destination? (ie. your \"backup\" location)"
		read DEST_DIR
		echo "DESTINATION_DIR=$DEST_DIR" >> $CONF_FILE

		# another courtesy check
		if [[ $DEST_DIR == "/" ]];
			then
				echo "Assuming / is a typo.."
				echo "Re-run this script and try again, in a less disaster-in-the-making directory.  Exiting.."
				rm .mergedev.cnf
				exit 0
		fi

		echo -e "\n\nAdmin directory? (this should be relative path; ie. /admin)"
		read ADMIN_DIR
		echo "ADMIN_DIR=$ADMIN_DIR" >> $CONF_FILE

		echo -e "\n\n### DATABASE CREDENTIALS ###\n"

		echo -e "\n\nHostname or IP address for the SOURCE database server:"
		read SOURCE_HOST
		echo "SOURCE_HOST=$SOURCE_HOST" >> $CONF_FILE

		echo -e "\n\nSource database name:"
		read SOURCE_DB
		echo "SOURCE_DB=$SOURCE_DB" >> $CONF_FILE

		echo -e "\n\nSource database user:"
		read SOURCE_USR
		echo "SOURCE_DB_USR=$SOURCE_USR" >> $CONF_FILE

		echo -e "\n\nSource database password:"
		read SOURCE_PWD
		echo "SOURCE_DB_PWD=$SOURCE_PWD" >> $CONF_FILE

		echo -e "\n\n## DESTINATION DB CREDENTIALS ##\n"

		echo -e "\n\nHostname or IP address for the DESTINATION database server:"
		read DEST_HOST
		echo "DEST_HOST=$DEST_HOST" >> $CONF_FILE

		echo "Destination database name:"
		read DEST_DB
		echo "DEST_DB=$DEST_DB" >> $CONF_FILE

		echo -e "\n\nDestination database user:"
		read DEST_USR
		echo "DEST_DB_USR=$DEST_USR" >> $CONF_FILE

		echo -e "\n\nDestination database password:"
		read DEST_PWD
		echo "DEST_DB_PWD=$DEST_PWD" >> $CONF_FILE

		echo -e "\n\nWould you like to erase your bash history?\n(You just entered a password via prompt; such is recommended.)\nEnter a LOWERCASE y to say yes and accept.\nHit enter to skip."
		read CLEAR_BASH

			if [[ $CLEAR_BASH == 'y' ]];
			then
				if [[ -f ~/.bash_history ]];
				then
					echo > ~/.bash_history
					echo "~/.bash_history emptied.  To confirm, run: tail ~/.bash_history in your terminal."
				else
					echo "~/.bash_history does not exist or exists as another filename, you\'ll want to manually remove it for added security, since I was unable to."
				fi
			fi

		echo -e "...DONE!\n"
		echo -e "Should you need to edit the config for this script in the future, you can find it at: "$PWD"/"$CONF_FILE""
		echo "To run this script (manually): ./mergedev.sh -- to auto run, create a cron pointing to:  "$PWD"/mergedev.sh"
		echo -e "Check the integrity of your backups regularly!\n"
		exit 0
	fi
