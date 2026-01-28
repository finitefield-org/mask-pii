set here [file dirname [file normalize [info script]]]
set root [file dirname [file dirname $here]]

lappend auto_path [file join $root tcl]

package require mask_pii 0.2.0

set masker [::mask_pii::Masker new]
$masker mask_emails
$masker mask_phones
$masker with_mask_char "#"

set input "Contact: alice@example.com or 090-1234-5678."
set output [$masker process $input]
puts $output

$masker destroy
