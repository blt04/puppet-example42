class ssmtp {

    package { ssmtp:
        name => $operatingsystem ? {
            default    => "ssmtp",
            },
        ensure => present,
    }

# ssmtp module is alternative to a sendmail module
# Here sendmail is simply removed

    package { sendmail:
        name => $operatingsystem ? {
            default    => "sendmail",
            },
        ensure => absent,
        require => Package["ssmtp"],
    }


    file {    
             "ssmtp.conf":
            mode => 644, owner => root, group => root,
            require => Package["ssmtp"],
            ensure => present,
            path => $operatingsystem ?{
                default => "/etc/ssmtp/ssmtp.conf",
            },
    }
    
    file {    
             "revaliases":
            mode => 644, owner => root, group => root,
            require => Package["ssmtp"],
            ensure => present,
            path => $operatingsystem ?{
                default => "/etc/ssmtp/revaliases",
            },
    }

    file { "ssmtp.aug":
        ensure => present,
        require => File['ssmtp.conf'],
        source => 'puppet:///modules/ssmtp/ssmtp.aug',
        path => $operatingsystem ?{
            default => '/usr/share/augeas/lenses/ssmtp.aug',
        },
    }

    # Set defaults so old scripts continue to work
    if(!$smtp_server)     { $smtp_server     = 'mail'       }
    if(!$mail_root_alias) { $mail_root_alias = 'postmaster' }

    augeas { "ssmtp.conf":
        context => "/files/etc/ssmtp/ssmtp.conf",
        require => File['ssmtp.aug'],
        changes => [
            "set mailhub ${smtp_server}",
            "set hostname ${fqdn}",
            "set root ${mail_root_alias}",
        ],
    }
}
