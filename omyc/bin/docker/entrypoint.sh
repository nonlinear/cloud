#!/bin/bash

# ================================
# start
# ================================
#
echo "==============================================="
echo "Start OMYC"
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "IP %s \n" "$_IP"
fi
echo "==============================================="



# ================================
# check folders
# ================================
mkdir /data/ >/dev/null 2>/dev/null
mkdir /data/users/ >/dev/null 2>/dev/null
mkdir /data/settings/ >/dev/null 2>/dev/null
mkdir /data/settings/btsync >/dev/null 2>/dev/null
mkdir /data/settings/cert >/dev/null 2>/dev/null
touch /data/settings/noip.conf >/dev/null 2>/dev/null
touch /data/settings/sync.conf >/dev/null 2>/dev/null
touch /etc/btsync/omyc.conf >/dev/null 2>/dev/null



# ================================
# if no users, create admin
# ================================
if [ ! -e /data/settings/users.sftp ]; then
	echo "No users. Create user admin/admin"
    #
	mkdir /data/users/admin >/dev/null 2>/dev/null
    chown -Rf www-data.www-data /data/users/admin/ >/dev/null 2>/dev/null
    chmod -Rf a-rwx,u+rwX /data/users/admin/ >/dev/null 2>/dev/null
    #
	touch /data/settings/users.web >/dev/null 2>/dev/null
	touch /data/settings/users.sftp >/dev/null 2>/dev/null
	touch /data/settings/groups.web >/dev/null 2>/dev/null
	touch /data/settings/groups.sftp >/dev/null 2>/dev/null
    #
	echo "admin"| /omyc/bin/ftpasswd --file /data/settings/users.sftp --passwd --name admin --home /data/users/admin/ --shell /bin/false --uid 33 --gid 33 --stdin  >/dev/null 2>/dev/null
	htpasswd -b /data/settings/users.web admin admin >/dev/null 2>/dev/null
    echo "admin:admin" > /data/settings/groups.web 
fi



# ================================
# if no cert, create cert
# ================================
if [ ! -e /data/settings/cert/active.crt ]; then
    cat /etc/ssl/certs/ssl-cert-snakeoil.pem > /data/settings/cert/active.crt
    cat /etc/ssl/private/ssl-cert-snakeoil.key > /data/settings/cert/active.key
    echo "-----BEGIN CERTIFICATE-----" > /data/settings/cert/active.ca 
    echo "-----END CERTIFICATE-----" >> /data/settings/cert/active.ca 
fi



# ================================
# fix permission
# ================================
chown -f www-data.www-data /data/ >/dev/null 2>/dev/null
chown -f www-data.www-data /data/users/ >/dev/null 2>/dev/null
chown -Rf www-data.www-data /data/settings/ >/dev/null 2>/dev/null
chown -f www-data.www-data /etc/btsync/omyc.conf >/dev/null 2>/dev/null
chmod -f a-rwx,a+rX,u+w /data/ >/dev/null 2>/dev/null
chmod -f a-rwx,a+rX,u+w /data/users/ >/dev/null 2>/dev/null
chmod -Rf a-rwx,u+rwX /data/settings/ >/dev/null 2>/dev/null
chmod -f a-rwx,u+rwX /etc/btsync/omyc.conf >/dev/null 2>/dev/null
chmod a+rw /dev/null




# ================================
# setup logs
# ================================
rm -f /var/log/api.server.log  >/dev/null 2>/dev/null
rm -f /var/log/apache2/access.log  >/dev/null 2>/dev/null
rm -f /var/log/apache2/error.log  >/dev/null 2>/dev/null
rm -f /var/log/proftpd/controls.log  >/dev/null 2>/dev/null
rm -f /var/log/proftpd/proftpd.log  >/dev/null 2>/dev/null
rm -f /var/log/apache2/other_vhosts_access.log >/dev/null 2>/dev/null
ln -s /dev/null /var/log/apache2/other_vhosts_access.log >/dev/null 2>/dev/null
if [ "$development" = "true" ]; then
    echo "Prepare log files for debug"
    touch /var/log/api.server.log >/dev/null 2>/dev/null
    touch /var/log/apache2/access.log >/dev/null 2>/dev/null
    touch /var/log/apache2/error.log >/dev/null 2>/dev/null
    touch /var/log/proftpd/controls.log >/dev/null 2>/dev/null
    touch /var/log/proftpd/proftpd.log >/dev/null 2>/dev/null
else
    # not debug. Lets point all logs to /dev/null so we create less garbage at fs
    ln -s /dev/null /var/log/api.server.log >/dev/null 2>/dev/null
    ln -s /dev/null /var/log/apache2/access.log >/dev/null 2>/dev/null
    ln -s /dev/null /var/log/apache2/error.log >/dev/null 2>/dev/null
    # proftp complain link to devnull... we need mute logs in different way
    #ln -s /dev/null /var/log/proftpd/controls.log >/dev/null 2>/dev/null
    #ln -s /dev/null /var/log/proftpd/proftpd.log >/dev/null 2>/dev/null
fi
chown -Rf www-data.www-data /var/log/api.server.log >/dev/null 2>/dev/null
chown -Rf www-data.www-data /var/log/apache2/ >/dev/null 2>/dev/null
chown -Rf www-data.www-data /var/log/proftpd/ >/dev/null 2>/dev/null
chmod -Rf a-rwx,a+rX,u+w /var/log/api.server.log >/dev/null 2>/dev/null
chmod -Rf a-rwx,a+rX,u+w /var/log/apache2/ >/dev/null 2>/dev/null
chmod -Rf a-rwx,a+rX,u+w /var/log/proftpd/ >/dev/null 2>/dev/null




# ================================
# setup cron 
# ================================
echo "* * * * * /omyc/bin/services/restart.if.need >/dev/null 2>/dev/null " > /tmp/mycron 2>/dev/null
echo "12 * * * * /omyc/bin/services/noip.update force >/dev/null 2>/dev/null " >> /tmp/mycron 2>/dev/null
crontab /tmp/mycron >/dev/null 2>/dev/null
rm /tmp/mycron >/dev/null 2>/dev/null
killall cron  >/dev/null 2>/dev/null
rm -f /var/run/crond.pid  >/dev/null 2>/dev/null



# ================================
# start services
# ================================
if [ "$development" = "true" ]; then
    echo "Start services in development mode"
	/omyc/bin/services/noip.update force 
	/etc/init.d/apache2 restart 
	/etc/init.d/proftpd restart 
	/etc/init.d/btsync restart 
	/usr/bin/sudo -u www-data /usr/bin/morbo -w /omyc/bin/api.server.pl -w /omyc/lib/ -v -l http://127.0.0.1:8080 /omyc/bin/api.server.pl  >>/var/log/api.server.log 2>>/var/log/api.server.log &
	cron -f  >/dev/null 2>/dev/null & 
else
    echo "Start services in production mode"
	/omyc/bin/services/noip.update force 
	/etc/init.d/apache2 restart 
	/etc/init.d/proftpd restart 
	/etc/init.d/btsync restart 
	/usr/bin/sudo -u www-data /usr/bin/morbo -l http://127.0.0.1:8080 /omyc/bin/api.server.pl  >>/dev/null 2>>/dev/null &
	cron -f  >/dev/null 2>/dev/null & 
fi



# ================================
# keep instance up
# ================================
echo "Show logs forever"
chmod a+rw /dev/null
tail -f -n 0 /var/log/apache2/* /var/log/proftpd/* /var/log/api.server.log 


