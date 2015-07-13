# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
#
# please file bugfixes or comments on http://bugs.otrs.org
#
# --
Summary:      OTRS Help Desk.
Name:         otrs
Version:      0.0
Copyright:    GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007
Group:        Applications/Mail
Provides:     otrs
# mod_perl removed for now, not available
Requires:     cronie httpd perl perl(Archive::Zip) perl(Crypt::SSLeay) perl(Date::Format) perl(DBI) perl(Digest::SHA) perl(IO::Socket::SSL) perl(LWP::UserAgent) perl(Net::DNS) perl(Net::LDAP) perl(Template) perl(URI) perl(XML::Parser) perl(XML::LibXML) perl(XML::LibXSLT)  perl-core procmail
#Requires:     cronie httpd mod_perl perl perl(Archive::Zip) perl(Crypt::SSLeay) perl(Date::Format) perl(DBI) perl(Digest::SHA) perl(IO::Socket::SSL) perl(LWP::UserAgent) perl(Net::DNS) perl(Net::LDAP) perl(Template) perl(URI) perl(XML::Parser) perl(XML::LibXML) perl(XML::LibXSLT) perl-core procmail
Autoreqprov:  no
Release:      01
Source0:      otrs-%{version}.tar.bz2
BuildArch:    noarch
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
<DESCRIPTION>

%prep
%setup

%build
# copy config file
cp Kernel/Config.pm.dist Kernel/Config.pm
cd Kernel/Config/ && for foo in *.dist; do cp $foo `basename $foo .dist`; done && cd ../../
# copy all crontab dist files
for foo in var/cron/*.dist; do mv $foo var/cron/`basename $foo .dist`; done
# copy all .dist files
cp .procmailrc.dist .procmailrc
cp .fetchmailrc.dist .fetchmailrc
cp .mailfilter.dist .mailfilter

%install
# delete old RPM_BUILD_ROOT
rm -rf $RPM_BUILD_ROOT
# set DESTROOT
export DESTROOT="/opt/otrs/"
# create RPM_BUILD_ROOT DESTROOT
mkdir -p $RPM_BUILD_ROOT/$DESTROOT/
# copy files
cp -R . $RPM_BUILD_ROOT/$DESTROOT
# install init-Script
install -d -m 755 $RPM_BUILD_ROOT/etc/rc.d/init.d
install -d -m 755 $RPM_BUILD_ROOT/etc/sysconfig
install -d -m 755 $RPM_BUILD_ROOT/etc/httpd/conf.d

install -m 755 scripts/redhat-rcotrs $RPM_BUILD_ROOT/etc/rc.d/init.d/otrs
install -m 644 scripts/redhat-rcotrs-config $RPM_BUILD_ROOT/etc/sysconfig/otrs

# copy apache2-httpd.include.conf to /etc/httpd/conf.d/zzz_otrs.conf
install -m 644 scripts/apache2-httpd.include.conf $RPM_BUILD_ROOT/etc/httpd/conf.d/zzz_otrs.conf

# set permission
export OTRSUSER=otrs
useradd $OTRSUSER || :
useradd apache || :
groupadd apache || :
$RPM_BUILD_ROOT/opt/otrs/bin/otrs.SetPermissions.pl --web-group=apache

%pre
# remember about the installed version
if test -e /opt/otrs/RELEASE; then
    cat /opt/otrs/RELEASE|grep VERSION|sed 's/VERSION = //'|sed 's/ /-/g' > /tmp/otrs-old.tmp
fi
# useradd
export OTRSUSER=otrs
echo -n "Check OTRS user ... "
if id $OTRSUSER >/dev/null 2>&1; then
    echo "$OTRSUSER exists."
    # update home dir
    usermod -d /opt/otrs $OTRSUSER
else
    useradd $OTRSUSER -d /opt/otrs/ -s /bin/bash -g apache -c 'OTRS System User' && echo "$OTRSUSER added."
fi


%post
export OTRSUSER=otrs
if test -e /opt/otrs/Kernel/Config/Files/ZZZAAuto.pm; then
    su $OTRSUSER -s /bin/bash -c "/opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild";
    su $OTRSUSER -s /bin/bash -c "/opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete";
fi

# note
HOST=`hostname -f`
echo ""
echo "Next steps: "
echo ""
echo "[httpd services]"
echo " Restart httpd 'service httpd restart'"
echo ""
echo "[install the OTRS database]"
echo " Make sure your database server is running."
echo " Use a web browser and open this link:"
echo " http://$HOST/otrs/installer.pl"
echo ""
echo "[OTRS services]"
echo " Start OTRS 'service otrs start' (service otrs {start|stop|status|restart)."
echo ""
echo "((enjoy))"
echo ""
echo " Your OTRS Team"
echo ""

%clean
rm -rf $RPM_BUILD_ROOT

%files
%config(noreplace) /etc/sysconfig/otrs
%config /etc/httpd/conf.d/zzz_otrs.conf
/etc/rc.d/init.d/otrs
<FILES>

%changelog
* Mon Dec 17 2012 - mb@otrs.com
- Added dependencies to Digest::SHA, Net::LDAP and Crypt::SSLeay, available from base repositories.
- Removed dependency on Time::HiRes in favor of perl-core package.
* Tue Dec 12 2012 - mb@otrs.com
- spec for RHEL6 created.
