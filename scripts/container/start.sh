#! /bin/sh

. `dirname $0`/dudle-config

INIT_LOCK_FILE=/var/tmp/dudle-container-initialized

if [ ! -e "$INIT_LOCK_FILE" ] && [ -e $BACKUP_FILE ]; then
    echo Restoring data from backup...
    cd $DUDLE_DIR
    tar xvfz $BACKUP_FILE
fi

touch $INIT_LOCK_FILE

rm -f /var/run/httpd/httpd.pid

httpd -DFOREGROUND

echo httpd exited

# in case of httpd errors, keep container up until maintenance arrives
sleep infinity
