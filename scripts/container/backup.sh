#! /bin/sh

. `dirname $0`/dudle-config

BACKUP_DIR=`dirname $BACKUP_FILE`
if [ ! -d "$BACKUP_DIR" ] || [ ! -d "$DUDLE_DIR" ]; then
    echo Directory error: \"$BACKUP_DIR\" or \"$DUDLE_DIR\"
    exit 1
fi

if [ -e $BACKUP_FILE ]; then
    OLD_BACKUP_FILE_TEMPLATE=`echo $BACKUP_FILE | sed 's/\.tar/-XXXXXXXXXX\.tar/g'`
    OLD_BACKUP_FILE=`mktemp $OLD_BACKUP_FILE_TEMPLATE`

    mv $BACKUP_FILE $OLD_BACKUP_FILE || exit 1

    find $BACKUP_DIR -name `basename $OLD_BACKUP_FILE_TEMPLATE | sed 's/-XXXXXXXXXX/-??????????/g'` -mtime +7 \
        -exec rm {} \;
fi

cd $DUDLE_DIR

BACKUP_FOLDERS="`find . -maxdepth 1 -type d | egrep -v '\./(extensions|locale|\.git|css)|^\.$' | xargs`"

echo Backing up folders: $BACKUP_FOLDERS

tar cfz $BACKUP_FILE $BACKUP_FOLDERS
