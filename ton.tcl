# leg20180331: ton / TON - Tcl Object Notation
#
# This package provides manipulation functionality for TON - a data
# serialization format with a direct mapping to JSON.
#
# In its essence, a JSON parser is provided, which can convert a JSON
# string into a Tcllib json style dictionary (dicts and arrays mixed),
# into a jimhttp style dictionary (only dicts) or into a nested, typed
# Tcl list.
#
# Finally, TON can be converted into (unformatted) JSON.

namespace eval ton {
    namespace export json2ton

    variable version 0.2
    
    proc json2ton json {
	lassign [jscan $json [string length $json]] i ton
	if {[set i [trr $json $i]]!=-1} {
	    error "json string invalid:$i: left over characters."
	}
	return $ton
    }

}
proc ton::trr {s i} {
    while {$i>=0 && ([set c [string index $s $i]] eq "\n" ||
		 [string is space $c])} {incr i -1}
    return $i
}
proc ton::jscan {json i {d :}} {
    set i [trr $json $i]
    if {$i<0} {return ""}
    switch -glob -- [set c [string index $json $i]] {
	[0-9.] {num $json $i $c $d}
	[el] {lit $json [incr i -1]}
	\" {str $json [incr i -1]}
	\] {arr $json [incr i -1]}
	\} {obj $json [incr i -1]}
	default {error "json string end invalid:$i: ..[string range $json $i-10 $i].."}
    }
}
proc ton::num {json i c d} {
    set float [expr {$c eq "."}]
    for {set j $i} {$i+1} {incr i -1} {
	if {[string match $d [set c [string index $json $i]]]} break
	set float [expr {$float || [string match "\[eE.]" $c]}]
    }
    if {!$i} {
	error "json string start invalid:$i: exhausted while parsing number."
    }
    set num [string trimleft [string range $json $i+1 $j]]
    if {!$float && [string is integer $num]} {
	    list $i "i $num"
    } elseif {$float && [string is double $num]} {
	list $i "d $num"
    } else {
	error "number invalid:[incr i]: $num."
    }
}
proc ton::lit {json i} {
    switch -exact -- [set c [string index $json $i]] {
	l {return [list [incr i -3] "l null"]}
	u {return [list [incr i -3] "l true"]}
	s {return [list [incr i -4] "l false"]}
	default {
	    set e [string range $json $i-4 $i+1]
	    error "literal invalid:$i: ..$e."
	}
    }
}
proc ton::str {json i} {
    for {set j $i} {$i} {incr i -1} {
	set i [string last \" $json $i]
	if {[string index $json $i-1] ne "\\"} break
    }
    if {$i<0} {
	error "json string start invalid:$i: exhausted while parsing string."
    }
    list [incr i -1] "s [list [string range $json $i+2 $j]]"
}
proc ton::arr {json i} {
    set r {}
    set i [trr $json $i]
    while {$i>=0 && [string index $json $i] ne "\["} {
	lassign [jscan $json $i "\[,\[]"] i v
	lappend r \[$v\]
	set i [trr $json $i]
	switch -exact [string index $json $i] {
	    , {incr i -1; continue}
	    \[ {return [list [incr i -1] "a [join [lreverse $r]]"]}
	    default {
		error "json string invalid:$i: parsing array."
	    }
	}
    }
    if {$i<0} {
	error "json string invalid:0: exhausted while parsing array."
    }
    return [list [incr i -1] a]
}
proc ton::obj {json i} {
    set r {}
    set i [trr $json $i]
    while {$i>=0 && [string index $json $i] ne "\{"} {
	lassign [jscan $json $i] i v
	set i [trr $json $i]
	if {[string index $json $i] eq ":"} {
	    lassign [jscan $json [incr i -1]] i k
	    lassign $k type k
	    if {$type ne "s"} {
		error "json string invalid:$i: key not a string."
	    }
	} else {
	    error "json string invalid:$i: parsing key in object."
	}
	lappend r \[$v\] [list $k]
	set i [trr $json $i]
	switch -exact [string index $json $i] {
	    , {incr i -1; continue}
	    \{ {return [list [incr i -1] "o [join [lreverse $r]]"]}
	    default {
		error "json string invalid:$i: parsing object."
	    }
	}
    }
    if {$i<0} {
	error "json string invalid:0: exhausted while parsing object."
    }
    return [list [incr i -1] o]
}
namespace eval ton::2list {
    proc atom {type v} {list $type $v}
    foreach type {i d s l} {
	interp alias {} $type {} [namespace current]::atom $type
    }
    proc a args {
	set r a
	foreach v $args {lappend r $v}
	return $r
    }
    proc o args {
	set r o
	foreach {k v} $args {lappend r $k $v}
	return $r
    }
    # There is plenty of room for validation in get
    # array index bounds
    # object key existence
    proc get {l args} {
	foreach k $args {
	    switch [lindex $l 0] {
		o {set l [dict get [lrange $l 1 end] $k]}
		a {set l [lindex $l [incr k]]}
		default {
		    error "error: key $k to long, or wrong data: [lindex $l 0]"
		}
	    }
	}
	return $l
    }
}
namespace eval ton::2dict {
    proc atom v {return $v}
    foreach type {i d l s} {
	interp alias {} $type {} [namespace current]::atom
    }
    proc a args {return $args}
    proc o args {return $args}
}
namespace eval ton::a2dict {
    proc atom v {return $v}
    foreach type {i d l s} {
	interp alias {} $type {} [namespace current]::atom
    }
    proc a args {
	set i -1
	set r {}
	foreach v $args {
	    lappend r [incr i] $v
	}
	return $r
    }
    proc o args {return $args}
}
namespace eval ton::2json {
    proc atom v {return $v}
    foreach type {i d l} {
	interp alias {} $type {} [namespace current]::atom
    }
    proc a args {
	return "\[[join $args {, }]]"
    }
    proc o args {
	set r {}
	foreach {k v} $args {lappend r "\"$k\": $v"}
	return "{[join $r {, }]}"
    }
    proc s s {return "\"$s\""}
}

package provide ton $ton::version
