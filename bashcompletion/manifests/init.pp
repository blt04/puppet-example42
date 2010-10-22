class bashcompletion {

    # Install
    package { "bash-completion":
        name => $operatingsystem ? {
            default => 'bash-completion',
        },
        ensure => present,
    }


    # Enable
    case $operatingsystem {
        ubuntu: {
            module_dir { 'bashcompletion': }

            file { "/var/lib/puppet/modules/bashcompletion/bash.bashrc.patch":
                ensure => present,
                content => template("bashcompletion/bash.bashrc.patch")
            }

            apply_patch { 'bash.bashrc-completion':
                file => '/etc/bash.bashrc',
                patchfile => '/var/lib/puppet/modules/bashcompletion/bash.bashrc.patch',
                require => [ Package['bash-completion'], File['/var/lib/puppet/modules/bashcompletion/bash.bashrc.patch'] ]
            }
        }
    }
}
