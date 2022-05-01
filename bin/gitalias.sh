#!/bin/bash
#
# gitalias.sh
#

cmd=git
opt="config --global --replace-all"

function showit(){
    $cmd config --global --get-regexp alias
}

function doit(){


    $cmd $opt  alias.ci "commit -m"
    $cmd $opt  alias.s  status
    $cmd $opt  alias.co checkout
    $cmd $opt  alias.h  "log --graph --format=oneline"
    $cmd $opt  alias.a  "add ."
    $cmd $opt  alias.p  push
    $cmd $opt  alias.l  "log --graph --format=oneline"
    $cmd $opt  alias.b  branch
    $cmd $opt  alias.u  pull
}

doit
showit
