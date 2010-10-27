#
# Define monitor::process::monit
#
# Nagios connector for monitor::process abstraction layer
# It's automatically used if "monit" is present in the $monitor_tool array
# By default it uses Example42 monit module, it can be adapted for third party modules
#
define monitor::process::monit (
    $pidfile,
    $process,
    $service,
    $enable
    ) {

    # Use for Example42 monit module
    monit::checkpid { "${process}":
        pidfile      => "${pidfile}",
        startprogram => "/etc/init.d/${service} start",
        stopprogram  => "/etc/init.d/${service} stop",
        enable       => $enable,
    }

}

