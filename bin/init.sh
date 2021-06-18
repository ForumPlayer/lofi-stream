#!/bin/bash
if [ ! -n "$(pidof mpd)" ]; then mpd; fi
bin="$(realpath "$0")"
${bin%/*}/runtime.sh