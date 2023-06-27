#!/bin/sh

# query the layout
setxkbmap -query

# if layout is $1 then 
setxkbmap -layout $2
# else
setxkbmap -layout $1