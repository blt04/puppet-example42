define mysql::grant (
    $mysql_db,
    $mysql_user,
    $mysql_privileges = "ALL",
    $mysql_host = "localhost"
) {

    include mysql

    $mysql_grant_filepath = '/var/lib/puppet/modules/mysql'
    if (!defined(File[$mysql_grant_filepath])) {
        file {$mysql_grant_filepath:
            path => $mysql_grant_filepath,
            ensure => directory,
            owner => root,
            group => root,
            mode => 700;
        }
    }

    if ($mysql_db == '*') {
        $mysql_grant_file = "mysqlgrant-$mysql_user-$mysql_host-all.sql"
    } else {
        $mysql_grant_file = "mysqlgrant-$mysql_user-$mysql_host-$mysql_db.sql"
    }

    file {
        "$mysql_grant_file":
            mode => 600, owner => root, group => root,
            ensure => present,
            path => "$mysql_grant_filepath/$mysql_grant_file",
            content => template("mysql/grant.erb"),
            replace => false;
    }

    exec {
        "mysqlgrant-$mysql_user-$mysql_host-$mysql_db":
            command => "mysql --defaults-file=/root/.my.cnf -uroot < $mysql_grant_filepath/$mysql_grant_file",
            require => [ Service["mysql"], File['/root/.my.cnf'], Exec["mysqluser-$mysql_user-$mysql_host"] ],
            subscribe => File["$mysql_grant_file"],
            refreshonly => true;
    }

}

