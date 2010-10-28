
# TODO: Puppet 2.6.2 doesn't support class inheritance when parameterized
# classes are used.  We currently are storing the version and gempath in
# both the ruby-passenger and ruby-passenger::apache classes.

class ruby-passenger {

    $ruby_passenger_version = '3.0.0'
    $ruby_passenger_gempath = '/usr/local/lib/ruby/gems/1.8/gems'


    package {
        'passenger':
            provider => 'gem',
            ensure => $ruby_passenger_version,
            alias => 'ruby-passenger',
            require => Package['ruby'];
    }
}


class ruby-passenger::apache($mininstances='2', $maxpoolsize='2') {

    include ruby-passenger
    include apache

    # TODO: How to inherit this from above?
    $ruby_passenger_version = '3.0.0'
    $ruby_passenger_gempath = '/usr/local/lib/ruby/gems/1.8/gems'

    # Dependencies
    if ! defined(Package['build-essential'])      { package { build-essential:      ensure => installed } }
    if ! defined(Package['apache2-prefork-dev'])  { package { apache2-prefork-dev:  ensure => installed } }
    if ! defined(Package['libapr1-dev'])          { package { libapr1-dev:          ensure => installed, alias => 'libapr-dev' } }
    if ! defined(Package['libaprutil1-dev'])      { package { libaprutil1-dev:      ensure => installed, alias => 'libaprutil-dev' } }
    if ! defined(Package['libcurl4-openssl-dev']) { package { libcurl4-openssl-dev: ensure => installed } }

    exec {
        'passenger-install-apache2-module':
            command => '/usr/local/bin/passenger-install-apache2-module -a',
            creates => "${ruby_passenger_gempath}/passenger-${ruby_passenger_version}/ext/apache2/mod_passenger.so",
            logoutput => 'on_failure',
            require => Package[
                'apache2',
                'ruby-passenger',
                'build-essential',
                'apache2-prefork-dev',
                'libapr-dev',
                'libaprutil-dev',
                'libcurl4-openssl-dev'
            ];
    }

    file {
        '/etc/apache2/mods-available/passenger.load':
            content => "LoadModule passenger_module ${ruby_passenger_gempath}/passenger-${ruby_passenger_version}/ext/apache2/mod_passenger.so",
            ensure => file,
            require => Exec['passenger-install-apache2-module'];

        '/etc/apache2/mods-available/passenger.conf':
            content => template('ruby/ruby-passenger-apache.conf.erb'),
            ensure => file,
            require => Exec['passenger-install-apache2-module'];

        '/etc/apache2/mods-enabled/passenger.load':
            ensure => 'link',
            target => '/etc/apache2/mods-available/passenger.load',
            require => File['/etc/apache2/mods-available/passenger.load'];

        '/etc/apache2/mods-enabled/passenger.conf':
            ensure => 'link',
            target => '/etc/apache2/mods-available/passenger.conf',
            require => File['/etc/apache2/mods-available/passenger.conf'];
    }

    # Add Apache restart hooks
    File['/etc/apache2/mods-available/passenger.load'] ~> Service['apache']
    File['/etc/apache2/mods-available/passenger.conf'] ~> Service['apache']
    File['/etc/apache2/mods-enabled/passenger.load']   ~> Service['apache']
    File['/etc/apache2/mods-enabled/passenger.conf']   ~> Service['apache']
}

class ruby-passenger::apache::disable {

    file {
        '/etc/apache2/mods-enabled/passenger.load':
            ensure => 'absent';
        '/etc/apache2/mods-enabled/passenger.conf':
            ensure => 'absent';
    }

    # Add Apache restart hooks
    if defined(Service['apache']) { File['/etc/apache2/mods-enabled/passenger.load']   ~> Service['apache'] }
    if defined(Service['apache']) { File['/etc/apache2/mods-enabled/passenger.conf']   ~> Service['apache'] }
}
