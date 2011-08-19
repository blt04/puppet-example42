class iptables::ubuntu {

    package {
        iptables:
            name => "iptables",
            ensure => present;
        iptables-persistent:
            name => "iptables-persistent",
            ensure => present;
    }

    file {
        'iptables-conf-dir':
            path => '/etc/iptables',
            ensure => 'directory',
            mode => '0755',
            owner => 'root',
            group => 'root';
        'iptables':
            path => '/etc/iptables/rules',
            ensure => 'file',
            mode => '0600',
            owner => 'root',
            group => 'root',
            content => $iptables_rules,
            require => [File['iptables-conf-dir'], Package['iptables-persistent']];
    }

    service {
        iptables-persistent:
            require => [ File["iptables"], Package['iptables'] ],
            enable => true,
            hasstatus => true,
            hasrestart => false,
            subscribe => File["iptables"];
    }
}

class iptables::ubuntu::disable inherits iptables::ubuntu {
    Service ["iptables-persistent"] {
        ensure => stopped,
        enable => false,
    }
}
