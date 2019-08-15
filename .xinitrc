#!/usr/bin/env sh 

# Commands are kept in .xprofile in the case that startx is not used
[ -f ~/.xprofile ] && . ~/.xprofile

# Start dwm
while true; do
    # Log stderror to a file 
    dwm 2> ~/.dwm.log
    # No error logging
    #dwm >/dev/null 2>&1
done
