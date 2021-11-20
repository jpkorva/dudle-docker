#! /bin/sh

CONTAINER_NAME=my-running-dudle
DOCKR=docker

get_existing() {
    CONTAINER_ID=`${DOCKR} ps -a --no-trunc --filter name=^/?${CONTAINER_NAME}$ --format "{{.ID}}"`

    if [ $? -ne 0 ] || [ "$CONTAINER_ID" = "" ]; then
        echo Dudle container not found $CONTAINER_ID
        exit 1
    fi
}

run() {
    TZ=`timedatectl show 2> /dev/null | grep Timezone | sed -e 's/Timezone=//g'`

    if [ "$TZ" = "" ]; then
        if [ -r /etc/timezone ]; then
            TZ=`cat /etc/timezone`
        fi
    fi

    if [ "$TZ" != "" ]; then
        TZ_PARAM="-e TZ=${TZ}"
    fi

    ${DOCKR} run -d -v /srv/dudle/backup:/backup:Z ${TZ_PARAM} -p 8888:80 --name ${CONTAINER_NAME} my-dudle || exit 1
}

backup() {
    echo Running backup for container $CONTAINER_ID

    ${DOCKR} exec $CONTAINER_ID /usr/local/bin/backup.sh || exit 1
}

connect() {
    echo Connecting to container $CONTAINER_ID

    ${DOCKR} exec -it $CONTAINER_ID /bin/bash
}

upgrade() {
    DOCKER_FILE=$SRC_DIR/Dockerfile
    if [ ! -d "$SRC_DIR" ] || [ ! -f $DOCKER_FILE ]; then
        echo $DOCKER_FILE does not exist
        exit 1
    fi
    cd $SRC_DIR
    FROM_IMAGE=`cat Dockerfile | sed 's/^[ \t]*//g' | grep "FROM " | cut -d" " -f2`
    ${DOCKR} pull $FROM_IMAGE || exit 1

    ( cd cgi; git pull ) || exit 1

    echo Creating new image...
    ${DOCKR} build -t my-dudle . || exit 1

    backup

    echo Stopping and removing old container...
    ${DOCKR} stop $CONTAINER_ID || exit 1
    ${DOCKR} rm $CONTAINER_ID || exit 1

    echo Creating a new container...
    run
}

for param in "$@"; do
    CONT=no
	case "$param" in
        --podman)
            DOCKR=podman
            CONT=yes
            ;;
        run)
            run
            ;;
        backup)
            get_existing
            backup
            ;;
        connect)
            get_existing
            connect
            ;;
        start)
            get_existing
            ${DOCKR} start $CONTAINER_ID
            ;;
        stop)
            get_existing
            ${DOCKR} stop $CONTAINER_ID
            ;;
        restart)
            get_existing
            ${DOCKR} stop $CONTAINER_ID || exit 1
            ${DOCKR} start $CONTAINER_ID
            ;;
        upgrade)
            get_existing

            SRC_DIR=`echo $0 | sed -e 's/scripts\/maintenance\/dudle-maint.sh//g'`
            [ "$SRC_DIR" != "" ] || SRC_DIR=./

            upgrade
            ;;
        logs)
            get_existing
            ${DOCKR} logs $CONTAINER_ID
            ;;
        *)
            echo "Usage: $0 [--podman] {run|backup|connect|start|stop|restart|upgrade|logs}"
            exit 1
    esac

    if [ "$CONT" == "no" ]; then
        exit 0
    fi
done

