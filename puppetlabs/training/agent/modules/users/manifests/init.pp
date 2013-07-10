class users {
user { 'rprashad':
  ensure           => 'present',
  gid              => 'destroyer',
  home             => '/home/rprashad',
  password         => '$1$Tge1IxzI$kyx2gPUvWmXwrCQrac8/m0',
  password_max_age => '99999',
  password_min_age => '0',
  shell            => '/bin/bash',
  uid              => '500',
}

user { 'rprashadio':
    ensure => 'absent',
}

group {  'destroyer':
    ensure => 'present',
}

}
