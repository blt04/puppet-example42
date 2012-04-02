#!/usr/bin/perl -w
#(@) (c) 2010 Slave_IO and Slave_SQL added by Joe DeCello <jdecello\@hotmail.com>.

use strict;
use Getopt::Long;
use DBI;

# Set DEFAULT inputs
my $options = {
    'master' => 'localhost', 'slave' => 'localhost',
    'port' => 3306, 'socket' => '', 'crit' => 100000, 'warn' => 10000,
    'csec' => 3600, 'wsec' => 600, 'noslave' => 'warn', 'debug' => 0
};
GetOptions($options, "master=s", "slave=s", "port=i", "socket=s", "noslave=s",
    "crit=i", "warn=i", "csec=i", "wsec=i", "debug", "help");
my $max_binlog;

if (defined $options->{'help'}) {
    print <<HELP;
$0: check replication between mysql databases

 $0 [ --master <host> ] [ --slave <host> ]
 [ --crit <positions> ] [ --warn <positions> ]
 [ --csec <seconds> ] [ --wsec <seconds> ]
 [ --noslave <ok|crit|warn> ]

  --master <host>    - MySQL instance running as a master server
  --slave <host>     - MySQL instance running as a slave server
  --port <port>      - port number MySQL is listening on
  --socket <socket>  - socket MySQL is listening on
  --crit <positions> - Number of binlog positions for critical state
  --warn <positions> - Number of binlog positions for warning state
  --csec <seconds>   - Number of seconds behind master for critical state
  --wsec <seconds>   - Number of seconds behind master for warning state
  --noslave <ok|crit|warn> - How the "no slaves defined" state is handled
  --help             - This help page

The user that is testing must be the same on all instances, eg:
  GRANT File, Process on *.* TO repl_test\@192.168.0.% IDENTIFIED BY <pass>

Note: Any mysqldump tables (for backups) may lock large tables for a long
time. If you dump from your slave for this, then your master will gallop
away from your slave, and the difference will become large. The trick is to
set crit above this differnce and warn below.

(c) 2004 Fotango. James Bromberger <jbromberger\@fotango.com>.
(c) 2006 Some changes by Robert Klikics <robert\@klikics.de>.
(c) 2010 Several fixes by Joe DeCello <jdecello\@hotmail.com>.
(c) 2010 Slave_IO and Slave_SQL added by Joe DeCello <jdecello\@hotmail.com>.
(c) 2010 Seconds behind master added by Brandon Turner <bturner\@bltweb.net>.

HELP
exit;
}

my $status = "";
my $severity = 0; # OK, 1 is WARNING, 2 is CRITICAL

my $return;

my $slave_ref = get_replication_status($options->{'slave'}, 'slave');

if((scalar keys %$slave_ref) == 0) {
    my $noslaveOpt = lc(substr $options->{'noslave'}, 0, 1);
    if ($noslaveOpt eq 'c') {
        print "CRIT";
        $return = 2;
    } elsif ($noslaveOpt eq 'w') {
        print "WARN";
        $return = 1;
    } else {
        print "OK";
        $return = 0;
    }
    print " - No slaves defined\n";
    exit $return;
}

my $master_ref = get_replication_status($options->{'master'}, 'master');

$return = check_slave_status ($slave_ref);
$severity = $return if ($return > $severity);

$return = compare_replication_status($master_ref, $slave_ref);
$severity = $return if ($return > $severity);

my $output = $status;
if ($severity >= 2) {
    print "CRITICAL - $output\n";
    exit 2; # CRITICAL
} elsif ($severity == 1) {
    print "WARN - $output\n";
    exit 1; # WARNING
}
print "OK - $output\n";
exit 0;

# end of main

###############
# Subroutines #
###############

sub get_replication_status {
    my $host = shift;
    my $role = shift;
    require Carp;
    Carp::cluck "host" if !defined $host;
    Carp::cluck "port" if !defined $options->{'port'};
    my $host_or_socket = "host=$host;port=$options->{'port'};";
    if ($options->{'socket'} && $options->{'socket'} ne '') {
        $host_or_socket = "mysql_socket=$options->{'socket'};";
    }
    my $dbh = DBI->connect("DBI:mysql:".$host_or_socket."mysql_read_default_file=$ENV{HOME}/.my.cnf");
    if (not $dbh) {
        print "UNKNOWN: cannot connect to $host";
        exit 3;
    }

    if (lc ($role) eq 'master') {
        my $sql1 = "show variables like 'max_binlog_size'";
        my $sth1 = $dbh->prepare($sql1);
        my $res1 = $sth1->execute;
        my $ref1 = $sth1->fetchrow_hashref;
        $max_binlog = $ref1->{'Value'};
    }
    my $sql = sprintf "SHOW %s STATUS", $role;
    my $sth = $dbh->prepare($sql);
    my $res = $sth->execute;
    if (not $res) {
        die "No results";
    }
    my $ref = $sth->fetchrow_hashref;
    $sth->finish;
    if ($options->{'debug'}) {
        print "$host:\n";
        print join (', ', map { sprintf " %s: %s", $_, $ref->{$_} }
            keys %{$ref}) . "\n";
    }
    $dbh->disconnect;
    return $ref;
}

#Check Delta between Master and Slave log/POS
sub compare_replication_status {
    my ($a, $b) = @_;
    my ($master, $slave);
    if (defined($a->{'File'})) {
        $master = $a;
        $slave = $b;
    } elsif (defined($b->{'File'})) {
        $master = $b;
        $slave = $a;
    }
    $master->{'File_No'} = $1 if ($master->{'File'} =~ /(\d+)$/);
    $slave->{'File_No'} = $1 if ($slave->{'Relay_Master_Log_File'} =~ /(\d+)$/);

    my $diff = ($master->{'File_No'} - $slave->{'File_No'}) * $max_binlog;

    printf "Master: %d Slave: %d\n", $master->{'Position'},
        $slave->{'Exec_Master_Log_Pos'} if $options->{'debug'};

    $diff+= $master->{'Position'} - $slave->{'Exec_Master_Log_Pos'};
    my $state = sprintf "Master: %d/%d, Slave: %d/%d, Diff: %d/%d",
        $master->{'File_No'}, $master->{'Position'},
        $slave->{'File_No'}, $slave->{'Exec_Master_Log_Pos'},
        ($diff/$max_binlog), ($diff % $max_binlog);
    $status .= "$state";
    if ($diff >= $options->{'crit'}) {
        return 2; # CRITICAL
    } elsif ($diff >= $options->{'warn'}) {
        return 1; # WARNING
    }
    return 0;
}

#Check for these too
#Slave_IO_Running: No
#Slave_SQL_Running: No
sub check_slave_status {
    my $slave = shift @_;

    printf "Slave_IO_Running: %s Slave_SQL_Running: %s Seconds_Behind_Master: %s\n",
        $slave->{'Slave_IO_Running'},
        $slave->{'Slave_SQL_Running'},
        defined($slave->{'Seconds_Behind_Master'}) ? $slave->{'Seconds_Behind_Master'} : 'NULL'
        if $options->{'debug'};

    my $state = sprintf "Slave IO: %s, Slave SQL: %s, Seconds Behind Master: %s,",
        $slave->{'Slave_IO_Running'},
        $slave->{'Slave_SQL_Running'},
        defined($slave->{'Seconds_Behind_Master'}) ? $slave->{'Seconds_Behind_Master'} : 'NULL';
    if ($slave->{'Last_Error'}) {
        $state .= sprintf " Last Error: %s,", $slave->{'Last_Error'};
    }

    $status .= "$state ";
    if ($slave->{'Slave_IO_Running'} ne 'Yes') {
        return 2; # CRITICAL
    } elsif ($slave->{'Slave_SQL_Running'} ne 'Yes') {
        return 2; # CRITICAL
    } elsif (!defined($slave->{'Seconds_Behind_Master'})) {
        return 2; # CRITICAL
    } elsif ($slave->{'Seconds_Behind_Master'} >= $options->{'csec'}) {
        return 2; # CRITICAL
    } elsif ($slave->{'Seconds_Behind_Master'} >= $options->{'wsec'}) {
        return 1; # WARNING
    }
    return 0; # OK
}

# end of subroutines

# END
