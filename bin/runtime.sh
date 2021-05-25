#!/bin/bash

function configs(){
###############################################################################################################################################

    scale="1280:720"
    #scale="852:480"
    fps=15

    OutputURL="rtmp://live.restream.io/live"
    #OutputURL="rtmp://live.twitch.tv/app"
    OutputKey="re_2952643_63bc41f0b45206d20ab2"
    
###############################################################################################################################################
}





function checkdeps(){
###############################################################################################################################################
    fail="no"
    if [ ! -n "$(which ffmpeg)" ]; then echo "FFmpeg is not installed!"; fail="yes"; fi
    if [ ! -n "$(which mpd)" ]; then echo "MPD is not installed!"; fail="yes"; fi
    if [ ! -n "$(which mpc)" ]; then echo "MPC is not installed!"; fail="yes"; fi
    if [ $fail == "yes" ]; then echo "Can't start streaming"; exit 1; fi
###############################################################################################################################################
}

function setup-stream() {
###############################################################################################################################################
    configs
    gop=$((fps*2))
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    VideoSourceURI="$(realpath background.gif)"
    #AudioSourceURI="http://127.0.0.1:4887"
    AudioSourceURI="/tmp/mpd.fifo"
    OverlaySourceURI="$(realpath $data/OverlayText.txt)"
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    VideoSource="-re -f gif -i $VideoSourceURI"
    #AudioSource="-f ogg -i $AudioSourceURI"
    AudioSource="-f s16le -i $AudioSourceURI"
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    #VideoConfig="-filter_complex realtime,scale=$scale,format=yuv420p"
    VideoConfig="-vf realtime,scale=$scale,format=yuv420p,drawtext=textfile='$OverlaySourceURI':x=50:y=50:fontsize=24:fontcolor=white:reload=1"
    AudioConfig="-c:a aac -ar 48000 -b:a 128k"
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    OutputConfig="-r $fps -g $gop -c:v libx264 -preset ultrafast -tune zerolatency"; #-profile:v baseline"
###############################################################################################################################################
}

function overlay(){
###############################################################################################################################################
    sleep 1
    while [ -n "$(pidof ffmpeg)" ]; do
        echo "Now playing: $(mpc current)" > $data/OverlayText.txt
        mpc current -w > /dev/null
    done
###############################################################################################################################################
}

function stream() { 
###############################################################################################################################################
    ffmpeg=$(which ffmpeg)

    if [ ! -n "$OutputKey" ]; then echo "OutputKey is not set! Can't start streaming"; exit 1; fi

    mkdir -p $logs
    echo "$$" > $bin/ffstream.pid
    $ffmpeg -hide_banner -stream_loop -1 $VideoSource -thread_queue_size 1024 $AudioSource $VideoConfig \
    $OutputConfig $AudioConfig -f flv $OutputURL/$OutputKey |& tee -a $logs/ffstream.$now.log
    rm $bin/ffstream.pid
###############################################################################################################################################
}

function checkvars(){
###############################################################################################################################################
    fail="no"
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    if [ ! -n "$VideoSourceURI" ]; then echo " is not set!"; fail="yes"; fi
    if [ ! -n "$AudioSourceURI" ]; then echo " is not set!"; fail="yes"; fi
    if [ ! -n "$OverlaySourceURI" ]; then echo " is not set!"; fail="yes"; fi
    if [ ! -n "$OutputURL" ]; then echo "OutputURL is not set!"; fail="yes"; fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    if [ $fail =="yes" ]; then echo "Can't start streaming"; exit 1; fi
###############################################################################################################################################
}



runtime=$(realpath $0)

bin=$(realpath $0)
bin=${bin%/*}

data=$(realpath $bin/../data)
logs=$(realpath $bin/../logs)
cd $data

pidfile="$bin/ffstream.pid"
now=$(date +"%F.%H-%M-%S")



##############################################################################################################################################

    if [ -n "$1" -a -z "$2" ]; then
        checkdeps

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

        # If started with arg --heartbeat, init heartbeat function #
        if [ $1 == "--stream" ]; then
            setup-stream
            stream
            exit
        fi

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

        # If started with arg --overlay, init overlay function #
        if [ $1 == "--overlay" ]; then
    	    configs
            overlay
            exit
        fi
    
        # If started with arg --refresh-overlay, refresh overlay text #
        if [ $1 == "--refresh-overlay" ]; then
            echo "Now playing: $(mpc current)" > $data/OverlayText.txt
            exit
        fi

        exit
    fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    
    if [ ! -f $pidfile ]; then
        overlay &
        #$runtime --overlay &
        setup-stream
        stream
        #$runtime --stream
    fi

###############################################################################################################################################




echo "end"
exit
