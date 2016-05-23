Introduction
============

This package runs [Dudle](https://dudle.inf.tu-dresden.de/) as a [Docker container](https://www.docker.com/).

Dudle stores data together with the code, which is a bit problematic from Docker point of view. This package contains 'scripts/maintenance/dudle-maint.sh' script that can be used to populate and back up polls to/from the container.

Installation
============

Fetch Dudle sources, create the Docker image and a folder for backups:

    # cd dudle-docker
    # git clone https://github.com/kellerben/dudle.git cgi
    # docker build -t my-dudle .
    # mkdir -p /srv/dudle/backup

If you have an existing Dudle installation and and you want to copy polls to the new container:

    # cd /your/old/dudle
    # tar cvfz /srv/dudle/backup/dudle-backup.tar.gz `find . -maxdepth 1 -type d | egrep -v '\./(extensions|locale|\.git|\.bzr|css)|^\.$' | xargs`

If you want to customize your installation, add your CSS and artwork to 'skin/css/' and create/modify 'skin/conf/config.rb'. For more information on customization, see "Pimp your Installation" section in Dudle README.

Create and start the container:

    # scripts/maintenance/dudle-maint.sh run

Dudle should be now running on port 8888.

If you want to co-locate Dudle with other services on port 80, you can use e.g. Apache httpd reverse proxy:

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

The following command updates all software:

    scripts/maintenance/dudle-maint.sh upgrade

The command creates a new image and container by upgrading the base image (currently Centos 7), Dudle sources and Dudle Docker image scripts. Before upgrade, all polls are backed up automatically.

Other commands
==============

* connect: Run a shell inside the container
* start: Start the container
* stop: Stop the container
* restart: Stop+start the container
* logs: See container log

