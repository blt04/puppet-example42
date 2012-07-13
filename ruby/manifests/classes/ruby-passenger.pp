
# TODO: Puppet 2.6.2 doesn't support class inheritance when parameterized
# classes are used.  We currently are storing the version and gempath in
# both the ruby-passenger and ruby-passenger::apache classes.

class ruby-passenger(
    $version = '3.0.0',
    $gempath = '/usr/local/lib/ruby/gems/1.8/gems'
) {
    package {
        'passenger':
            provider => 'gem',
            ensure => $version,
            alias => 'ruby-passenger',
            require => Package['ruby'];
    }
}


class ruby-passenger::apache(
    $mininstances = '1',
    $maxpoolsize = '6',
    $poolidletime = '300',
    $maxinstancesperapp = '0',
    $spawnmethod = 'smart-lv2',
    $version = '3.0.0',
    $gempath = '/usr/local/lib/ruby/gems/1.8/gems'
) {

    class { 'ruby-passenger': version => $version, gempath => $gempath }
    include ruby-passenger
    include apache

    # Dependencies
    if ! defined(Package['build-essential'])      { package { build-essential:      ensure => installed } }
    if ! defined(Package['apache2-prefork-dev'])  { package { apache2-prefork-dev:  ensure => installed } }
    if ! defined(Package['libapr1-dev'])          { package { libapr1-dev:          ensure => installed, alias => 'libapr-dev' } }
    if ! defined(Package['libaprutil1-dev'])      { package { libaprutil1-dev:      ensure => installed, alias => 'libaprutil-dev' } }
    if ! defined(Package['libcurl4-openssl-dev']) { package { libcurl4-openssl-dev: ensure => installed } }

    exec {
        'passenger-install-apache2-module':
            command => '/usr/local/bin/passenger-install-apache2-module -a',
            creates => "${gempath}/passenger-${version}/ext/apache2/mod_passenger.so",
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
            content => "LoadModule passenger_module ${gempath}/passenger-${version}/ext/apache2/mod_passenger.so\n",
            ensure => file,
            require => Exec['passenger-install-apache2-module'];

        '/etc/apache2/mods-available/passenger.conf':
            content => template('ruby/ruby-passenger-apache.conf.erb'),
            ensure => file,
            require => Exec['passenger-install-apache2-module'];

        '/etc/apache2/mods-enabled/passenger.load':
            ensure => 'link',
            target => '../mods-available/passenger.load',
            require => File['/etc/apache2/mods-available/passenger.load'];

        '/etc/apache2/mods-enabled/passenger.conf':
            ensure => 'link',
            target => '../mods-available/passenger.conf',
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
