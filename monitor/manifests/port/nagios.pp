#
# Define monitor::port::nagios
#
# Nagios connector for monitor::port abstraction layer
# It's automatically used if "nagios" is present in the $monitor_tool array
# By default it uses Example42 nagios module, it can be adapted for third party modules
#
define monitor::port::nagios (
    $target,
    $port,
    $protocol,
    $enable
    ) {

    $ensure = $enable ? {
        "false"   => "absent",
        "true"    => "present",
    }

    # Use for Example42 , Immerda and DavidS derived nagios modules
    nagios::service { "$name":
        ensure      => $ensure,
        check_command => $protocol ? {
            tcp => "check_tcp!${port}",
            udp => "check_udp!${port}",
        }
   }

    # Use for Camptocamp (You can choose alternatives for distributed environent)
    # nagios::service::distributed { "$name":
    #    ensure      => $ensure,
    #    check_command => $protocol ? {
    #        tcp => "check_tcp!${port}",
    #        udp => "check_udp!${port}",
    #        }
    # }

}


