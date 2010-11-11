
#TODO: Adapt to other operating systems!

define apache::module($module, $conf='false') {

    if !defined(File["/etc/apache2/mods-enabled/$module.load"]) {
        file {"/etc/apache2/mods-enabled/$module.load":
            ensure => link,
            target => "../mods-available/$module.load",
            require => Package['apache'],
            notify => Service['apache'];
        }
    }

    if ($conf!='false') {
        if !defined(File["/etc/apache2/mods-enabled/$module.conf"]) {
            file {"/etc/apache2/mods-enabled/$module.conf":
                ensure => link,
                target => "../mods-available/$module.conf",
                require => Package['apache'],
                notify => Service['apache'];
            }
        }
    }
}
