# Auto sync of development & production databases and directories
Total rewrite for 2018 -- first run of the script via terminal will guide you through creating a config file for both directory and database backups.  No need to manually configure anything.

## Automate backups
Add a cron to sync backups: `30 1 * * * /path/to/mergedev.sh > /dev/null`

Note: It is not recommended to blackhole stderr for this; if something goes awry with permissions, you'll want to be notified.

## Set an alias if you'd like to trigger the script manually, opposed to predetermined times with cron
`nano ~/.bashrc`

Add the following to the end of the file:

`alias mergedev='/your/path/to/mergedev.sh'`

Update your config without requiring logout:

`. ~/.bashrc`

All set.

To trigger the script, run `mergedev`


### Some considerations
It is recommended to run this script in a non-public directory.  Wherever it is first ran, it will generate a .cnf file in that directory.

Also not recommended to use the root database user; ideally, you'll have a user specifically for backups, granted only the required permissions to perform the backup/dump/inserts.

Only used for local database backups; has not been tested for remote.
