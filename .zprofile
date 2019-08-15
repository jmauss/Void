#!/usr/bin/env sh

# Add ~/.local/bin to path
export PATH="$PATH:$HOME/.local/bin/"

# Default programs
export EDITOR=/usr/bin/vi

# Start x server if not already running
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    exec startx
fi
