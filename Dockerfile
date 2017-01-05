# preparations:
# git clone https://github.com/bkmgit/dudle.git cgi
#
# build:
# docker build -t my-dudle .
#
# run:
# docker run -it -p 8888:80 -v /srv/dudle-backup:/backup:Z  --rm --name my-running-dudle my-dudle
#
# build partly based on https://github.com/fonk/docker-dudle/blob/master/Dockerfile
FROM fedora:24
RUN dnf -y install httpd ruby ruby-devel git bison flex glib2 glib2-devel rubygems gcc make wget gettext gettext-devel
RUN dnf -y install tar which glibc-all-langpacks glibc-langpack-en rubygem-i18n
RUN dnf clean all
RUN gem install fast_gettext gettext locale
RUN export RUBYOPT="-KU -E utf-8:utf-8"
RUN wget marcin.owsiany.pl/potool/potool-0.16.tar.gz
RUN tar -xvf potool-0.16.tar.gz
WORKDIR potool-0.16
RUN make -f Makefile
RUN make install
WORKDIR /

RUN git clone https://github.com/bkmgit/dudle.git cgi 
WORKDIR cgi 
# Need to build with localization support
RUN LC_ALL=en_US.utf8 make 

WORKDIR /

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
