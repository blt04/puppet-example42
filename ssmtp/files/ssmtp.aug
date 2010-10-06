(* ssmtp module for Augeas
 Author: Brandon Turner <bturner@bltweb.net>

 ssmtp.conf is a standard INI File.
*)

module Ssmtp =
  autoload xfm


(************************************************************************
 * INI File settings
 *
 * ssmtp.conf only supports "# as commentary and "=" as separator
 *************************************************************************)
let comment  = IniFile.comment "#" "#"
let sep      = IniFile.sep "=" "="
let empty    = IniFile.empty


(************************************************************************
 *                        ENTRY
 * ssmtp.conf uses standard INI File entries
 *************************************************************************)
let entry   = IniFile.entry IniFile.entry_re sep comment


(************************************************************************
 *                        RECORD
 * ssmtp.conf doesn't use [title]'s, so we just use a series of entries
 *************************************************************************)
let record      = ( entry | empty ) *


(************************************************************************
 *                        LENS & FILTER
 *************************************************************************)
let lns     = record
(* let lns    = record_anon? . record* *)

let filter = (incl "/etc/ssmtp/ssmtp.conf")

let xfm = transform lns filter
