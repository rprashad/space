# System authorization information
auth  --useshadow  --enablemd5

# System bootloader configuration
bootloader --location=mbr --append="biosdevname=0"

# Partition clearing information
clearpart --all --initlabel

# Use text mode install
text

# Firewall configuration
firewall --disable

# Run the Setup Agent on first boot
firstboot --disable

# System keyboard
keyboard us

# System language
lang en_US

# Use network installation
url --url=$tree

# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza

# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot

# Root password
rootpw --iscrypted $default_password_crypted

# SELinux configuration
selinux --disabled

# Do not configure the X Window System
skipx

# System timezone
timezone  America/New_York

# Install OS instead of upgrade
install

# Clear the Master Boot Record
zerombr

# Create Partition(s)
part /boot      --fstype ext4   --size=512
part pv.01 --size=1 --grow

# Standard Volume Group(s)
volgroup "$(hostname)_os" pv.01

# Logical Volume(s)
logvol  /           --vgname="$(hostname)_os" --size=6048  --name=root --fstype ext4
logvol  swap        --vgname="$(hostname)_os" --size=1048  --name=swap --fstype swap
logvol  /usr        --vgname="$(hostname)_os" --size=30720 --name=usr --fstype ext4
logvol  /tmp        --vgname="$(hostname)_os" --size=15360 --name=tmp --fstype ext4
logvol  /var        --vgname="$(hostname)_os" --size=30720 --name=var --fstype ext4
logvol  /home       --vgname="$(hostname)_os" --size=30720 --name=home --fstype ext4
logvol  /opt        --vgname="$(hostname)_os" --size=40960 --name=data --fstype ext4

%pre
$SNIPPET('log_ks_pre')
$kickstart_start
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')

%packages --nobase
$SNIPPET('func_install_if_enabled')
$SNIPPET('puppet_install_if_enabled')
@core
openssh-clients

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('puppet_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps

echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Begin EPEL Repository Installation
echo "Fetching EPEL Repository"
rpm -Uhv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

echo "Running makecache"
yum makecache
echo "Installing puppet"
yum -y install puppet
echo "Installing factor"
yum -y install facter
echo "Installing perl-core"
yum -y install perl-core
echo "Disabling Zeroconf"
grep -q '^NOZEROCONF=yes' /etc/sysconfig/network || sed -i -e '/^NETWORKING=yes/a NOZEROCONF=yes' /etc/sysconfig/network
echo "Disabling IPv6"
grep -q '^NETWORKING_IPV6=no' /etc/sysconfig/network || sed -i -e '/^NETWORKING=yes/a NETWORKING_IPV6=no' /etc/sysconfig/network
# Enable Puppet plugins
sed -i '/ssldir/ a\    pluginsync = true' /etc/puppet/puppet.conf

# Turn services off
chkconfig postfix off
chkconfig rhnsd off
chkconfig rhsmcertd off

# Disable rhsmd cron job
sed -i 's+^/usr/libexec/rhsmd+# /usr/libexec/rhsmd+g' /etc/cron.daily/rhsmd

# Configure Puppet
/sbin/chkconfig --level 345 puppet on
/bin/sed -i 's+^#PUPPET_SERVER=.*+PUPPET_SERVER=puppet+g' /etc/sysconfig/puppet
/usr/sbin/puppetd -tv
/etc/init.d/puppet once -v
/etc/init.d/puppet start

$kickstart_done
# End final steps
