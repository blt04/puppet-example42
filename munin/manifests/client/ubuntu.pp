class munin::client::ubuntu inherits munin::client::package {
    # the plugin will need that
    package { "iproute": ensure => installed }

    File["/etc/munin/munin-node.conf"]{
            content => template("munin/munin-node.conf.$operatingsystem.$lsbdistcodename"),
    }
    # workaround bug in munin_node_configure
    plugin { "postfix_mailvolume": ensure => absent }
    include munin::plugins::ubuntu
}
