#!/bin/bash
bin=$(realpath $0)
bin=${bin%/*}
cd $bin
#######################################################################################
if [ -n "$1" -a -z "$2" ]; then
#######################################################################################
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
    if [ $1 == "enable" ]; then
        chmod 744 $PWD/streamer.sh
        systemctl link $PWD/stream.service
	systemctl daemon-reload
        systemctl enable stream
        exit
    fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    if [ $1 == "disable" ]; then
        $0 stop
	    systemctl disable stream
        exit
    fi
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
    if [ $1 == "start" ]; then
        screen -dmS "streaming" $bin/streamer.sh
        exit
    fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    if [ $1 == "stop" ]; then
        pkill -P $(cat ffstream.pid)
        kill $(cat ffstream.pid)
        rm $bin/ffstream.pid 2> /dev/null
        exit
    fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    if [ $1 == "restart" -o $1 == "reload" ]; then
        $0 stop
        $0 start
        exit
    fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    if [ $1 == "status" ]; then
	systemctl status stream
        exit
    fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    if [ $1 == "tty" ]; then
        screen -dr "streaming"
        exit
    fi

#######################################################################################
else
     systemctl status stream
    exit
fi


