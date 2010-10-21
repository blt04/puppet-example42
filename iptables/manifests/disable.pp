# Disables iptables (no boot, no run)
class iptables::disable {
    case $operatingsystem {
        centos: { include iptables::redhat::disable }
        redhat: { include iptables::redhat::disable }
        ubuntu: { include iptables::ubuntu::disable }
        default: { err("No such operatingsystem: $operatingsystem yet defined") }
    }
}
