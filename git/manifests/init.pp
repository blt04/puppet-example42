class git {

	$git_basedir="/srv/git"
        
	package { "git":
                name => $operatingsystem ? {
                        ubuntu  => "git-core",
                        default => "git",
                        },
                ensure => present,
        }

}

import "classes/*.pp"
import "definitions/*.pp"
