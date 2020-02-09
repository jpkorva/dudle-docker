#! /bin/sh

CONTAINER_NAME=my-running-dudle

get_existing() {
    CONTAINER_ID=`docker ps -a --no-trunc --filter name=^/${CONTAINER_NAME}$ --format "{{.ID}}"`

    if [ $? -ne 0 ] || [ "$CONTAINER_ID" = "" ]; then
        echo Dudle container not found $CONTAINER_ID
        exit 1
    fi
}

run() {
    docker run -d -v /srv/dudle/backup:/backup:Z -p 8888:80 --name ${CONTAINER_NAME} my-dudle || exit 1
}

backup() {
    echo Running backup for container $CONTAINER_ID

    docker exec $CONTAINER_ID /usr/local/bin/backup.sh || exit 1
}

connect() {
    echo Connecting to container $CONTAINER_ID

    docker exec -it $CONTAINER_ID /bin/bash
}

upgrade() {
    DOCKER_FILE=$SRC_DIR/Dockerfile
    if [ ! -d "$SRC_DIR" ] || [ ! -f $DOCKER_FILE ]; then
        echo $DOCKER_FILE does not exist
        exit 1
    fi
    cd $SRC_DIR
    FROM_IMAGE=`cat Dockerfile | sed 's/^[ \t]*//g' | grep "FROM " | cut -d" " -f2`
    docker pull $FROM_IMAGE || exit 1

    ( cd cgi; git pull ) || exit 1

    echo Creating new image...
    docker build -t my-dudle . || exit 1

    backup

    echo Stopping and removing old container...
    docker stop $CONTAINER_ID || exit 1
    docker rm $CONTAINER_ID || exit 1

    echo Creating a new container...
    run
}

case "$1" in
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
        docker start $CONTAINER_ID
        ;;
    stop)
        get_existing
        docker stop $CONTAINER_ID
        ;;
    restart)
        get_existing
        docker stop $CONTAINER_ID || exit 1
        docker start $CONTAINER_ID
        ;;
    upgrade)
        get_existing

        SRC_DIR=`echo $0 | sed -e 's/scripts\/maintenance\/dudle-maint.sh//g'`
        [ "$SRC_DIR" != "" ] || SRC_DIR=./

        upgrade
        ;;
    logs)
        get_existing
        docker logs $CONTAINER_ID
        ;;
    *)
        echo "Usage: $0 {run|backup|connect|start|stop|restart|upgrade|logs}"
esac

