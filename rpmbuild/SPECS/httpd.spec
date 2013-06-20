Name:           httpd
Version:        2.2.22
Release:        1%{?dist}
Summary:       %{name} %{version} RPM 
Group:         web 
License:       GPLv3+ 
Source0:       ftp://host.com/httpd-2.2.22.tar.gz

BuildPreReq: apr-devel, apr-util-devel, openldap-devel, db4-devel, expat-devel, findutils, perl, pkgconfig, zlib-devel, openssl-devel, libxml2-devel, libjpeg-devel, openssl-devel, zlib-devel
BuildPreReq: /usr/bin/apr-1-config, /usr/bin/apu-1-config
Requires: apr >= 1.0.2, apr-util >= 1.0.2, gawk, /usr/bin/find, openldap, openssl, logrotate, /usr/bin/passwd
PreReq: /sbin/chkconfig, /bin/mktemp, /bin/rm, /bin/mv
PreReq: sh-utils, textutils, /usr/sbin/useradd
Provides: webserver
Provides: httpd-mmn = %{mmn}
Conflicts: thttpd
Obsoletes: apache, secureweb, mod_dav

%description

%prep
%setup -n httpd-2.2.22

%build
%configure
./configure --enable-so \
--prefix=/opt/httpd \
--enable-rewrite \
--with-ssl  \
--enable-ssl \
--enable-expires \
--enable-deflate \
--enable-headers  \
--disable-asis \
--disable-autoindex \
--disable-userdir \
--disable-actions
make %{?_smp_mflags}


%install
%make_install
rm -rf %{buildroot}/httpd
install -m 0755 -d %{buildroot}/%{name}

%post
/usr/sbin/useradd -u 2000 -d /home/web -m -s /bin/bash web
/usr/bin/passwd -l web

/bin/cat <<EOF > /etc/profile.d/local-bin.sh
# local/bin ENV Setup
export PATH="\$PATH:/usr/local/bin"
EOF

. /etc/profile.d/local-bin.sh
cd /opt/httpd/conf/extra
for I in `ls`; do cp $I $I.ORIG; done

cp /opt/httpd/conf/httpd.conf /opt/httpd/conf/httpd.conf.ORIG
cp /opt/httpd/bin/envvars /opt/httpd/bin/envvars.ORIG
cp /opt/httpd/bin/apachectl /opt/httpd/bin/apachectl.ORIG

echo "APACHE_ULIMIT='ulimit -n 20480 -u 8192'" >> /opt/httpd/bin/envvars
echo "export APACHE_ULIMIT" >> /opt/httpd/bin/envvars
sed -i "s/^ULIMIT_MAX_FILES\=/\#ULIMIT_MAX_FILES\=/" /opt/httpd/bin/apachectl

sed -i "64a\ " /opt/httpd/bin/apachectl
sed -i "64a\fi" /opt/httpd/bin/apachectl
sed -i "64a\     ULIMIT_MAX_FILES=\"\$APACHE_ULIMIT\"" /opt/httpd/bin/apachectl
sed -i "64a\else" /opt/httpd/bin/apachectl
sed -i "64a\     ULIMIT_MAX_FILES=\"ulimit -S -n \`ulimit -H -n\`\"" /opt/httpd/bin/apachectl
sed -i "64a\then" /opt/httpd/bin/apachectl
sed -i "64a\if [ ! \"\$APACHE_ULIMIT\" ]" /opt/httpd/bin/apachectl
sed -i "64a\# Used to control the ulimit options in apache" /opt/httpd/bin/apachectl
sed -i "64a\ " /opt/httpd/bin/apachectl

mkdir -p /opt/httpd/conf/sites
mkdir -p /opt/httpd/conf/mods
mkdir -p /opt/httpd/conf/SSL
mkdir -p /opt/web_sites
mkdir -p /opt/web_sites/Apps
mkdir -p /opt/web_sites/Tmp
chown -R web:web /opt/web_sites

cat <<EOF > /etc/logrotate.d/httpd
/opt/httpd/logs/*_log {
        daily
        missingok
        rotate 7
        compress
        notifempty
        create 644 root root
        sharedscripts
        postrotate
                if [ -f /opt/httpd/logs/httpd.pid ]; then
                        /etc/init.d/httpd restart > /dev/null
                fi
        endscript
}
EOF



%preun
if [ $1 = 0 ] ; then
/sbin/install-info --delete %{_infodir}/%{name}.info %{_infodir}/dir || :
fi

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,web,web,-)
/opt/*
%doc

%changelog
