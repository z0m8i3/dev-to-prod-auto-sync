# Development to production/testing auto sync via command line
Quick & dirty script to sync dev & testing environments, similarly to rsync; but also updating config & htaccess files all in one swoop.

The script is hardcoded for Apache/.htaccess usage; if using nginx, modify accordingly.
Also tested & confirmed to work in Mac environments, but will require some tweaking. (Linux distros are better, anyway)

## Configure your script
Modify the configuration variables at the top of mergedev.sh to set your appropriate filepaths & database credentials

## Set an alias if you'd like to trigger the script manually, opposed to predetermined times with cron
`nano ~/.bashrc`

Add the following to the end of the file:

`alias mergedev='/your/path/to/mergedev.sh'`

Update your config without requiring logout:

`. ~/.bashrc`

All set.

To trigger the script, run `mergedev`
