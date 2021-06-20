#!/bin/bash
if [ ! -n "$(pidof mpd)" ]; then mpd; fi
if [ ! -n "$(mpc queue)" ]; then echo -e "Queue is Empty! \nOpening default shell."; $SHELL; exit; fi
if [ ! -n "$(mpc current)" ]; then mpc play; fi
bin="$(realpath "$0")"
${bin%/*}/runtime.sh