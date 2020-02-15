#!/bin/sh

# munin-cron will run on container start. Otherwise we would get an error message while trying to access the Web UI
su munin -c munin-cron || /bin/true
# Start cron jobs
/etc/init.d/cron start
# Start http service
/usr/local/bin/munin-httpd
