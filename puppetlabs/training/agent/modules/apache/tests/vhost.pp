include apache
apache::vhost { "rprashad.puppetlabs.vm":
    docowner => $apache::www_user,
    docgroup => $apache::www_group,
    #    port     => 81,
}
apache::vhost { "crazyhorse.puppetlabs.vm":
    docowner => $apache::www_user,
    docgroup => $apache::www_group,
    #port     => 82,
}
