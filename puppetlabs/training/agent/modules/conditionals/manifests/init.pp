class conditionals {

case $::operatingsystem {
    'redhat' : { $content = "Red Hat box\n" }
    'centos' : { $content = "CentOS box\n" }
}

  file { "/tmp/os" : 
    ensure => present,
    content   => $content
  }
}


