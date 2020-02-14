FROM ubuntu:19.10 as munin-build

ENV MUNIN_VERSION 2.999.14

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    make \
    perl \
    unzip \
    gcc \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Perl dependencies
RUN yes | cpan Module::Build

# Install munin
RUN cd /tmp && wget https://github.com/munin-monitoring/munin/archive/${MUNIN_VERSION}.zip && \
    unzip ${MUNIN_VERSION}.zip && \
    cd /tmp/munin-${MUNIN_VERSION} && \
    perl Build.PL && \
    ./Build installdeps && \
    make && \
    make install && \
    cd && rm /tmp/munin-2.999.14 -r

FROM ubuntu:19.10 as munin

RUN apt-get update && apt-get install -y \
    libhttp-server-simple-cgi-prefork-perl \
    rrdtool \
    librrds-perl \
    libio-string-perl \
    libxml-dumper-perl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=0 /usr/local/bin/munin-* /usr/local/bin/
COPY --from=0 /usr/local/etc/munin/ /usr/local/etc/munin/
COPY --from=0 /usr/local/share/munin/ /usr/local/share/munin/
COPY --from=0 /usr/local/share/perl/5.28.1/Munin /usr/local/share/perl/5.28.1/Munin
COPY --from=0 /usr/local/share/perl/5.28.1/Munin.pm /usr/local/share/perl/5.28.1/Munin.pm

RUN useradd munin

# Initialize directories and sample config
RUN mkdir -p /var/run/munin && \
    chown -R munin:munin /var/run/munin && \
    mkdir -p /var/lib/munin/ && \
    chown munin /var/lib/munin/ -R

# Munin config
ADD munin.conf /usr/local/etc/munin/munin.conf

# HTTP server
ADD run.sh /etc/service/munin/run

# munin-cron
ADD cron-entry /etc/cron.d/munin

# munin-cron will run on container start. Otherwise we would get an error message while trying to access the Web UI
ADD startup /etc/my_init.d/munin

# http service
EXPOSE 4948/tcp
# munin-node service
# EXPOSE 4949/tcp

VOLUME /var/lib/munin /var/log/munin /usr/local/etc/munin/munin-conf.d

CMD ["/usr/local/bin/munin-httpd"]
