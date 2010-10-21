class iptables {

    if(!$iptables_rules) { $iptables_rules = template('iptables/default-rules.erb') }

    case $operatingsystem {
        centos: { include iptables::redhat }
        redhat: { include iptables::redhat }
        ubuntu: { include iptables::ubuntu }
        default: { warning("No such operatingsystem: $operatingsystem yet defined") }
    }

}
