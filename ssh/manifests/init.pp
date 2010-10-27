import "*.pp"

class ssh {

    case $operatingsystem {
        ubuntu: {}
        default: {
            package { ssh:
                name   => $operatingsystem ? {
                    default    => "openssh",
                },
                ensure => present,
            }
        }
    }

    package { ssh-client:
        name   => $operatingsystem ? {
            ubuntu     => 'openssh-client',
            default    => "openssh-clients",
            },
        ensure => present,
    }

}

class ssh::server {

    include ssh

    package { ssh-server:
        name   => $operatingsystem ? {
            default    => "openssh-server",
            },
        ensure => present,
    }

    service { sshd:
        name => $operatingsystem ? {
            ubuntu  => "ssh",
            default => "sshd",
            },
        ensure => running,
        enable => true,
        hasrestart => true,
        hasstatus => true,
        status => $operatingsystem ? {
            ubuntu => '/etc/init.d/ssh status',
            default => '/etc/init.d/sshd status'
        },
        require => Package["ssh-server"],
        subscribe => File["sshd.conf"],
    }

    file { "sshd.conf":
            mode => 600, owner => root, group => root,
            require => Package["ssh-server"],
            ensure => present,
            path => $operatingsystem ?{
                default => "/etc/ssh/sshd_config",
            },
    }

}

define ssh::server::config ($value) {

    # Augeas version. 
    augeas {
        "sshd_config_$name":
        context =>  "/files/etc/ssh/sshd_config",
        changes =>  "set $name $value",
        onlyif  =>  "get $name != $value",
        # onlyif  =>  "match $name/*[.='$value'] size == 0",
    }

    # Davids' replaceline version (to fix) 
    # replaceline {
    #    "sshd_config_$name":
    #    file => "/etc/ssh/sshd_config",
    #    pattern => "$name",
    #    replacement => "^$name $value",
    # }
}


define ssh::client::config ($host='\*', $name, $value) {

    # The /etc/ssh/ssh_config lense doesn't exist by default
    if (!defined(File['/usr/share/augeas/lenses/ssh.aug'])) {
        file {
            '/usr/share/augeas/lenses/ssh.aug':
                ensure => present,
                mode => 0644,
                source => 'puppet:///modules/ssh/ssh.aug';
        }
    }

    if ($host != '\*') and (!defined(Augeas["ssh_config_insert_$host"])) {
        augeas {
            "ssh_config_insert_$host":
                context => '/files/etc/ssh/ssh_config',
                changes => "ins $host before \\*",
                onlyif  => "match $host size == 0",
                require => File['/usr/share/augeas/lenses/ssh.aug'];
        }
    }


    augeas {
        "ssh_config_${host}_${name}":
            context => "/files/etc/ssh/ssh_config/$host",
            changes => "set $name $value",
            require => $host ? {
                '\*' => File['/usr/share/augeas/lenses/ssh.aug'],
                default => [ File['/usr/share/augeas/lenses/ssh.aug'], Augeas["ssh_config_insert_$host"] ],
            }
    }
}
