Introduction
============

This package runs [DuD-Poll](https://dud-poll.inf.tu-dresden.de/) (former Dudle) as a [Docker container](https://www.docker.com/).

The poll data is stored inside the container. However, it can be backed up or populated from/to the container by using the included 'scripts/maintenance/dudle-maint.sh' script.

Installation
============

Fetch DuD-Poll sources, create the Docker image and a folder for backups:

    # cd dudle-docker
    # git clone https://github.com/kellerben/dudle.git cgi
    # docker build -t my-dudle .
    # mkdir -p /srv/dudle/backup

If you have an existing DuD-Poll/Dudle installation and want to copy polls to the new container:

    # cd /your/old/dudle
    # tar cvfz /srv/dudle/backup/dudle-backup.tar.gz `find . -maxdepth 1 -type d | egrep -v '\./(extensions|locale|\.git|\.bzr|css)|^\.$' | xargs`

If you want to customize your installation, add your CSS and artwork to 'skin/css/' and create/modify 'skin/conf/config.rb'. For more information on customization, see "Pimp your Installation" section in DuD-Poll README.

Create and start the container:

    # scripts/maintenance/dudle-maint.sh run

DuD-Poll should be now running on port 8888.

If you want to co-locate DuD-Poll with other services on port 80, you can use e.g. Apache httpd reverse proxy:

    <VirtualHost *:80>
      ServerName dudle.example.com

      CustomLog /var/log/httpd/access_dudle_log combined

      # note: requires "setsebool -P httpd_can_network_connect 1" if Selinux is enabled
      ProxyPreserveHost on
      ProxyPass / http://localhost:8888/
      ProxyPassReverse / http://localhost:8888/
    </VirtualHost>

Container backup
================

Create an archive of all polls:

    scripts/maintenance/dudle-maint.sh backup

The latest archive is '/srv/dudle/backup/dudle-backup.tar.gz'.

Container upgrade
=================

The following command updates all involved software:

    scripts/maintenance/dudle-maint.sh upgrade

A new image and a container are created by upgrading the base image (currently Redhat ubi8), DuD-Poll sources and maintenance scripts. All polls are backed up automatically before upgrade and restored afterwards.

Other commands and parameters for dudle-maint.sh
================================================

* --podman: Use Podman instead of Docker
* connect: Run a shell inside the container
* start: Start the container
* stop: Stop the container
* restart: Stop+start the container
* logs: See container log

