(*
Module: Ssh
  Parses /etc/ssh/ssh_config

Author: Brandon Turner <bturner@bltweb.net>

About: Reference
  ssh_config man page.

About: License
  This file is licensed under the LGPL v2+.

About: Lens Usage
  Sample usage of this lens in augtool:

    * Get your current setup
      > print /files/etc/ssh/ssh_config
      ...

    * Add a new host
      > ins /files/etc/ssh/ssh_config/mynewhost.com before /files/etc/ssh/ssh_config/\*
      > set /files/etc/ssh/ssh_config/mynewhost.com/User differentuser

  Saving your file:

      > save

About: CAVEATS

  In ssh_config, the first obtained value will be used.  Thus, the order of
  "Host" specifications matters.  You should be careful to always insert Host
  specifications in the right order, especially the last catch-all host.

About: Configuration files
  This lens applies to /etc/ssh/ssh_config

*)

module Ssh =
   autoload xfm

   let eol = Util.eol
   let sep = del /[ \t]*=[ \t]*|[ \t]+/ " "
   let hostkey_re = /Host/
   let key_re = /[A-Za-z0-9]+/ - hostkey_re

   let sto_to_eol = Util.del_opt_ws "" . store /([^ \t\n].*[^ \t\n]|[^ \t\n])/
   let sto_to_comment  = store /[^#= \t\n][^#\n]*[^# \t\n]|[^#= \t\n]/

   let comment = [ label "#comment" . Util.del_opt_ws "" . del /#/ "#" . sto_to_eol? . eol ]
   let host  = Util.del_opt_ws "" . del hostkey_re "Host" . sep . key /[A-Za-z0-9_\.\*-]+/ . eol
   let entry = [ Util.del_opt_ws "    " . key key_re . sep . sto_to_comment . (comment|eol) ]
   let empty = [ eol ]
   let record = [ host . (entry|empty|comment)* ]

   let lns = (comment|empty)* . record*

   let xfm = transform lns (incl "/etc/ssh/ssh_config")





(*
let example_file = "# An opening comment

Host my-fake-host
   HostName=myrealhost.com

Host *
#  ForwardAgent no
   SendEnv LANG LC_*
   #HashKnownHosts yes\n"


test Ssh.lns get example_file =
  { "#comment" = "An opening comment" }
  { }
  {"my-fake-host"
    { "HostName" = "myrealhost.com" }
    { }
  }
  {"*"
    { "#comment" = "ForwardAgent no" }
    { "SendEnv" = "LANG LC_*" }
    { "#comment" = "HashKnownHosts yes" }
  }


test Ssh.lns put example_file after
    insb "anotherhost.com" "\*" ;
    set "anotherhost.com/HostName" "ssh.anotherhost.com" ;
    insa "" "anotherhost.com/HostName"
= "# An opening comment

Host my-fake-host
   HostName=myrealhost.com

Host anotherhost.com
   HostName ssh.anotherhost.com

Host *
#  ForwardAgent no
   SendEnv LANG LC_*
   #HashKnownHosts yes
"
*)
