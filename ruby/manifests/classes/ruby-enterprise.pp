
class ruby-enterprise {

    file { "/var/lib/puppet/modules/ruby":
        ensure => directory,
    }

    file { "/var/lib/puppet/modules/ruby/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb":
        source => 'puppet:///modules/ruby/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb',
        ensure => present,
    }

    package {
        ruby-enterprise:
            provider => 'dpkg',
            source   => '/var/lib/puppet/modules/ruby/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb',
            ensure   => 'installed',
            alias    => 'ruby';
    }

}
