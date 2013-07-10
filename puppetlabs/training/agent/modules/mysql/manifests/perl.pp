# Class: mysql::perl
#
# This class installs the perl libs for mysql.
#
# Parameters:
#   [*ensure*]       - ensure state for package.
#                        can be specified as version.
#   [*package_name*] - name of package
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::perl(
  $package_name   = $mysql::params::perl_package_name,
  $package_ensure = 'present'
) inherits mysql::params {

  package { 'perl-mysqldb':
    ensure => $package_ensure,
    name   => $package_name,
  }

}
