# preparations:
# git clone https://github.com/kellerben/dudle.git cgi
#
# build:
# docker build -t my-dudle .
#
# run:
# docker run -it -p 8888:80 -v /srv/dudle-backup:/backup:Z  --rm --name my-running-dudle my-dudle

FROM centos

# dudle-maint.sh attempts to set container timezone the same as the host has. Alternatively it can be defined here:
#ENV TZ=Europe/Helsinki

# centos needs to be pointed at vaults of its repos, which are now deprecated
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum -y install httpd ruby ruby-devel git rubygems gcc make epel-release wget redhat-rpm-config
RUN gem install gettext iconv
RUN yum clean all

CMD [ "/usr/local/bin/start.sh" ]

COPY ./scripts/container/ /usr/local/bin/

COPY ./html/ /var/www/html/
COPY ./cgi/ /var/www/html/cgi-bin/

RUN sed -i \
        -e 's/^<Directory "\/var\/www\/html">/<Directory "\/var\/www\/html-original">/g' \
        -e 's/^ *ScriptAlias \/cgi-bin\//#ScriptAlias \/cgi-bin\//g' \
        /etc/httpd/conf/httpd.conf \
    && sed -ri \
		's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
		s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g;' \
		/etc/httpd/conf/httpd.conf
COPY ./conf/httpd/dudle.conf /etc/httpd/conf.d/

COPY ./skin/css/ /var/www/html/cgi-bin/css/
COPY ./skin/conf/ /var/www/html/cgi-bin/

RUN chmod -R go-w /var/www/html/cgi-bin
RUN chgrp apache /var/www/html/cgi-bin
RUN chmod 775 /var/www/html/cgi-bin

RUN cd /var/www/html/cgi-bin && \
    for i in locale/?? locale/??_??; do \
        wget -O $i/dudle.mo https://dudle.inf.tu-dresden.de/locale/`basename $i`/dudle.mo; \
    done

