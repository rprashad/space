class apache {
  case $::osfamily {
    'redhat' : { 
      $package = 'httpd'
      $www_user = 'apache'
      $www_group = 'apache'
      $conf_file = '/etc/httpd/conf/httpd.conf'
      $confd_file = '/etc/httpd/conf.d'
      $service = 'httpd'
    }
    'debian' : { 
      $package = ['apache2', 'apache2-common']
      $www_user = 'www-data'
      $www_group = 'www-data'
      $conf_file = '/etc/apache2/apache2.conf'
      $confd_file = '/etc/apache2/conf.d'
      $service = 'apache2'
    }
    default  : { 
      fail("Invalid os ${::osfamily}")
    }
  }
  package { $package :
    ensure => 'present',
  }
  user { $www_user :
    ensure => 'present',
    gid    => $www_group,
  }
  group { $www_group :
    ensure => 'present',
  }
  file { $conf_file :
    ensure => 'file',
    source => 'puppet:///modules/apache/httpd.conf',
    require   => Package[$package],
  }

  service { $service :
    ensure    => running,
    enable    => true,
    require   => Package[$package],
    subscribe => File[$conf_file],
  }
  File {
    owner => $www_user,
    group => $www_group,
    mode  => '0644',
  }

  file { '/var/www' :
    ensure => 'directory',
  }
  file { '/var/www/html' :
    ensure => 'directory',
  }
  file { '/var/www/html/index.html' :
    ensure => 'file',
    content => template('apache/index.html.erb'),
  }
}
