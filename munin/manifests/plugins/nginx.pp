class munin::plugins::nginx inherits munin::plugins::base {
    munin::plugin{ "nginx_request": }
    munin::plugin{ "nginx_status": }
    case $::operatingsystem {
      Ubuntu: {
        if !defined(Package['liblwp-useragent-determined-perl']) { package {'liblwp-useragent-determined-perl': ensure => 'installed';} }
      }
    }
}
