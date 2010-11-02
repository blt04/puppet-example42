
# This is designed to work with camptocamp's mysql module, not
# example42's
class nrpe::mysql {

    if $mysql_exists == 'true' {

        $mysql_user = 'nagios'
        $mysql_host = 'localhost'
        $mysql_password = inline_template("<%= (1..25).collect{|a| (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + %w(% & * + - : ? @ ^ _))[rand(75)] }.join %>")

        mysql_user {"${mysql_user}@${mysql_host}":
            ensure => present,
            initial_password_hash => mysql_password($mysql_password),
            require => [Package["mysql-server"], Service["mysql"]],
            notify => Exec['Generate /etc/nagios/.my.cnf'];
        }

        mysql_grant { "${mysql_user}@${mysql_host}":
            privileges => 'repl_client_priv',
            require => Mysql_user["${mysql_user}@${mysql_host}"];
        }

        exec { "Generate /etc/nagios/.my.cnf":
            command     => "/bin/echo -e '[mysql]\\nuser=${mysql_user}\\npassword=${mysql_password}\\n[mysqladmin]\\nuser=${mysql_user}\\npassword=${mysql_password}\\n[mysqldump]\\nuser=${mysql_user}\\npassword=${mysql_password}\\n[mysqlshow]\\nuser=${mysql_user}\\npassword=${mysql_password}\\n[client]\\nuser=${mysql_user}\\npassword=${mysql_password}' > /etc/nagios/.my.cnf",
            refreshonly => true,
            require => [Mysql_user["${mysql_user}@${mysql_host}"], Package['nrpe']];
        }

        file { "/etc/nagios/.my.cnf":
            owner => nagios,
            group => nagios,
            mode  => 600,
            require => [Package['nrpe'], Exec['Generate /etc/nagios/.my.cnf']];
        }
    }
}
