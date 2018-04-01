Title:		*ton* and TON
Subtitle:   Tcl Object Notation and some code to manipulate it
Author:		Georg Lehner
Copyright:	Georg Lehner <jorge@at.anteris.net>, 2018


What is it
----------

*ton* was born as a pure Tcl JSON parser. It parses JSON from right to
left and it is faster than other comparable tools, at least on Tcl8.6
and in March 2018.


How it works
------------

*ton* provides a function to convert a JSON string into TON - a data
representation equivalent to JSON.  TON stands for Tcl Object
Notation, every TON representation is a Tcl script.

TON is decoded by defining six functions: `o`, `a`, `s`, `i`, `d` and
`l`, which decode their argument(s) as object, array, string, number
(`i` .. integer, `d` .. double float)  and literal respectively.

*ton* provides namespaces with these function sets for decoding TON into:

`ton::2list`:
:    a nested Tcl lists

`ton::2dict`:
:    a Tcl dictionary in the same format as the jimhttp JSON parser.

`ton::a2dict`:
:    a Tcl dictionary in the same format as the Tcllib JSON parser.

`ton::2json`:
:__  an unformatted JSON string.

The function `ton::json2ton` converts a JSON string into TON. In order
to convert a JSON dict in the variable `json` to the Tcllib dictionary
format you would run the following:

	namespace eval ton::2dict [ton::json2ton $json]]


How to choose a Tcl decoder
---------------------------

`ton::a2dict` is the most user friendly decoder, and the fastest one
for general workload.  All data is extracted with a single:

	dict get $data key key ...


`ton::2list` allows for type checking on access and is faster for huge
arrays.  Data is extracted best with a provided access function

	ton::2list::get $data key key ...


`ton::2dict` seems fastest when processing small JSON strings.  Data
extraction for mixed array and object data is cumbersome.  Suppose we
have an array of objects and want to get the email of the 43rd object:

	dict get [lindex $data 43] email


Design Goals
------------

*ton* provides a small parser implementation which can be included
directly in source code into a Tcl script and parses JSON correctly,
without overstretching correctness.


Caveats
-------

`ton::json2ton` will parse the rightmost valid JSON construct in a
string, and terminate. No check is done for extra characters.

Other then taking care of backslash escaped quotes `\"` on parsing, no
processing for backslash escapes is done.

Numbers are only validated with Tcl's string is function. Hex or octal
numbers in the JSON string are therefore admissible.

**Security**: TON should be executed in a save slave interpreter to
avoid arbitrary code execution with malicious crafted JSON or TON
strings. I believe, that `ton::json2ton` does not generate dangerous
TON, but this has not been scrutinized.


References
----------

Original article:
http://at.magma-soft.at/sw/blog/posts/Reverse_JSON_parsing_with_TCL

Tcler's Wiki: http://wiki.tcl.tk/55239

Repository: http://at.magma-soft.at/darcs/ton


License Terms
-------------

In order to comply with general usage in the Tcl/Tk community *ton* is
released under a BSD style license, copied directly from the Tcllib
source tree and available in the file `license.terms`
