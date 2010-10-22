class ntpbase {
    package { ntp:
        name => $operatingsystem ? {
            default    => "ntp",
            },
        ensure => present,
    }
}

class ntp inherits ntpbase {

    service { ntpd:
        name => $operatingsystem ? {
            suse => "ntp",
            debian => "ntp",
            ubuntu => "ntp",
            default => "ntpd",
            },
        ensure => running,
        enable => true,
        hasrestart => true,
        hasstatus => true,
        status => $operatingsystem ? {
            ubuntu => '/etc/init.d/ntp status',
            default => '/etc/init.d/ntpd status'
        },
        require => Package[ntp],
        subscribe => File["ntp.conf"],
    }

    file {    
             "ntp.conf":
#            mode => 644, owner => root, group => root,
            require => Package[ntp],
            ensure => present,
            path => $operatingsystem ?{
                default => "/etc/ntp.conf",
            },
    }
    
    file {    
             "/etc/ntp/keys":
#            mode => 600, owner => root, group => root,
            require => Package[ntp],
            ensure => present,
            path => $operatingsystem ?{
                suse    => "/etc/ntp.keys",
                debian  => "/etc/ntp.keys",
                ubuntu  => "/etc/ntp.keys",
                default => "/etc/ntp/keys",
            },
    }

}


class ntp::disabled inherits ntp {
    Service['ntpd'] {
        enable => false,
        ensure => stopped,
    }

}

class ntpdate inherits ntpbase {

    file {    
             "/etc/cron.hourly/ntpdate":
            mode => 755, owner => root, group => root,
            require => Package[ntp],
            content => template("ntp/ntpdate"),
    }
    
}
