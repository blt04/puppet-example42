class vim {

    # Install
    package { "vim":
        name => $operatingsystem ? {
            default => 'vim',
        },
        ensure => present,
    }


    # Enable custom settings
    case $operatingsystem {
        ubuntu: {
            module_dir { 'vim': }

            file { "/var/lib/puppet/modules/vim/vimrc.patch":
                ensure => present,
                content => template("vim/vimrc.patch")
            }

            apply_patch { 'vimrc-lastposition':
                file => '/etc/vim/vimrc',
                patchfile => '/var/lib/puppet/modules/vim/vimrc.patch',
                require => [ Package['vim'], File['/var/lib/puppet/modules/vim/vimrc.patch'] ]
            }
        }
    }
}
