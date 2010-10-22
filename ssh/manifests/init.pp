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

define ssh::config ($value) {

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
