#! /bin/sh

. `dirname $0`/dudle-config

INIT_LOCK_FILE=/var/tmp/dudle-container-initialized

if [ ! -e "$INIT_LOCK_FILE" ] && [ -e $BACKUP_FILE ]; then
    echo Restoring data from backup...
    cd $DUDLE_DIR
    tar xvfz $BACKUP_FILE
fi

touch $INIT_LOCK_FILE

httpd -DFOREGROUND

echo httpd exited
