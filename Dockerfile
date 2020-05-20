FROM ubuntu:20.04 as munin-build

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    make \
    unzip \
    perl \
    rrdtool \
    libdbi-perl \
    liburi-perl \
    librrds-perl \
    libjson-perl \
    libnet-snmp-perl \
    libio-string-perl \
    libxml-dumper-perl \
    libnet-server-perl \
    libnet-ssleay-perl \
    libdbd-sqlite3-perl \
    libxml-dumper-perl \
    libsub-identify-perl \
    liblog-dispatch-perl \
    liblist-moreutils-perl \
    libio-socket-inet6-perl \
    libautobox-list-util-perl \
    libparams-validate-perl \
    libparams-validate-perl \
    libhtml-template-pro-perl \
    libparallel-forkmanager-perl \
    libhttp-server-simple-cgi-prefork-perl \
    libclone-perl \
    libpango1.0-dev \
    libdbd-pg-perl \
    libfile-copy-recursive-perl \
    libfile-readbackwards-perl \
    libfile-slurp-perl \
    libhtml-template-perl \
    libhttp-server-simple-perl \
    libio-stringy-perl \
    liblog-log4perl-perl \
    libmodule-build-perl \
    libnet-dns-perl \
    libnet-ip-perl \
    libtest-class-perl \
    libtest-deep-perl \
    libtest-differences-perl \
    libtest-exception-perl \
    libtest-longstring-perl \
    libtest-mockmodule-perl \
    libtest-mockobject-perl \
    libtest-perl-critic-perl \
    libwww-perl \
    libxml-libxml-perl \
    libxml-parser-perl \
    && rm -rf /var/lib/apt/lists/*

ENV MUNIN_VERSION 2.999.14

# Install munin
RUN update-ca-certificates && \
    cd /tmp && wget https://github.com/munin-monitoring/munin/archive/${MUNIN_VERSION}.zip && \
    unzip ${MUNIN_VERSION}.zip && \
    echo '127.0.0.1 testing.acme.com' >> /etc/hosts && \
    cd /tmp/munin-${MUNIN_VERSION} && \
    useradd munin && \
    make && \
    make test && \
    make install && \
    cd && rm /tmp/munin-${MUNIN_VERSION} -r

RUN ls /usr/local/share/perl/

FROM ubuntu:19.10 as munin

RUN apt-get update && apt-get install -y --no-install-recommends \
    cron \
    perl \
    rrdtool \
    libdbi-perl \
    liburi-perl \
    librrds-perl \
    libjson-perl \
    libnet-snmp-perl \
    libio-string-perl \
    libxml-dumper-perl \
    libnet-server-perl \
    libnet-ssleay-perl \
    libdbd-sqlite3-perl \
    libxml-dumper-perl \
    libsub-identify-perl \
    liblog-dispatch-perl \
    liblist-moreutils-perl \
    libio-socket-inet6-perl \
    libautobox-list-util-perl \
    libparams-validate-perl \
    libparams-validate-perl \
    libhtml-template-pro-perl \
    libparallel-forkmanager-perl \
    libhttp-server-simple-cgi-prefork-perl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=0 /usr/local/bin/munin-* /usr/local/bin/
COPY --from=0 /usr/local/etc/munin/ /usr/local/etc/munin/
COPY --from=0 /usr/local/share/munin/ /usr/local/share/munin/
COPY --from=0 /usr/local/share/perl/ /usr/local/share/perl/
# COPY --from=0 /usr/local/share/perl/5.28.1/Munin /usr/local/share/perl/5.28.1/Munin
# COPY --from=0 /usr/local/share/perl/5.28.1/Munin.pm /usr/local/share/perl/5.28.1/Munin.pm

# Initialize directories and sample config
RUN mkdir -p /var/run/munin && \
    useradd munin && \
    chown -R munin:munin /var/run/munin && \
    mkdir -p /var/lib/munin/ /usr/local/etc/munin/munin-conf.d && \
    chown munin /var/lib/munin/ /usr/local/etc/munin/munin-conf.d -R

# Munin config
ADD munin.conf /usr/local/etc/munin/munin.conf

# munin-cron
ADD cron-entry /etc/cron.d/munin

RUN crontab /etc/cron.d/munin

ADD entrypoint.sh /entrypoint.sh

# http service
EXPOSE 4948/tcp
# munin-node service
# EXPOSE 4949/tcp

VOLUME /var/lib/munin /var/log/munin

ENTRYPOINT /entrypoint.sh
