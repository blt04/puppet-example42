# handle if_ and if_err_ plugins
class munin::plugins::interfaces inherits munin::plugins::base {

    $munin_interfaces = gsub($interfaces, "lo", "")
    $ifs = gsub(split($munin_interfaces, " |,"), "(.+)", "if_\\1")
    munin::plugin {
    $ifs: ensure => "if_";
    }
    case $operatingsystem {
    openbsd: {
        $if_errs = gsub(split($munin_interfaces, " |,"), "(.+)", "if_errcoll_\\1")
          munin::plugin{
        $if_errs: ensure => "if_errcoll_";
      }
    }
    default: {
        $if_errs = gsub(split($munin_interfaces, " |,"), "(.+)", "if_err_\\1")
          munin::plugin{
            $if_errs: ensure => "if_err_";
      }
    }
    }
}
