define apache::vhost (
  $docowner,
  $docgroup,
  $confdir = $apache::confd_file,
  $priority = '10',
  $options = 'Indexes MultiViews',
  $vhost_name = $name,
  $servername = $name,
  $docroot = "/var/www/${name}",
  $port = '80',
){
  host { $servername:
    ip => $::ipaddress,
  }
  File {
    owner => $docowner,
    group => $docgroup,
    mode  => '0644',
  }
  file { "${confdir}/${name}.conf":
    ensure  => file,
    notify  => Service[$apache::service],
    content => template('apache/vhost.conf.erb'),
    require => Package[$apache::package],
  }
  file { $docroot : 
    ensure => directory,
  }
  file { "${docroot}/index.html":
    ensure  =>  file,
    content => template("apache/index.html.erb"),
  }
}
