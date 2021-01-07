#!/bin/bash
streamer=$(realpath $0)
bin=$(realpath $0)
bin=${bin%/*}
data=$(realpath $bin/../data)
logs=$(realpath $bin/../logs)
cd $data

now=$(date +"%F.%H-%M-%S")



function heartbeat(){
#######################################################################################
    if [ ! -n "$HeartbeatKey" ]; then echo "HeartbeatKey is not set!"; exit; fi
    HeartbeatURL="https://heartbeat.uptimerobot.com"
    HeartbeatDelay=55
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
    while [ -f "$bin/ffstream.pid" ]; do
        wget -q --spider "$HeartbeatURL/$HeartbeatKey" > /dev/null
        sleep $HeartbeatDelay
    done
#######################################################################################
}



function overlay(){
#######################################################################################
    while [ -f "$bin/ffstream.pid" ]; do
        echo "Now playing: $(mpc current)" > $data/OverlayText.txt
        mpc current -w > /dev/null
    done
#######################################################################################
}



function stream() {
#######################################################################################

    ffmpeg=$(which ffmpeg)

    VideoSourceURI="$(realpath background.gif)"
    AudioSourceURI="http://127.0.0.1:4887"
    OverlaySourceURI="$(realpath OverlayText.txt)"
    
    VideoSource="-re -f gif -i $VideoSourceURI"
    AudioSource="-f ogg -i $AudioSourceURI"
    fps=15
    gop=$((fps*2))

    scale="1280:720"
    #scale="852:480"

    #VideoConfig="-filter_complex realtime,scale=$scale,format=yuv420p"
    VideoConfig="-vf realtime,scale=$scale,format=yuv420p,drawtext=textfile='$OverlaySourceURI':x=50:y=50:fontsize=24:fontcolor=white:reload=1"
    AudioConfig="-c:a aac -ar 48000 -b:a 128k"
    OutputConfig="-r $fps -g $gop -c:v libx264 -preset ultrafast -tune zerolatency"; #-profile:v baseline"
    
    #OutputURL="rtmp://live.restream.io/live"
    OutputURL="rtmp://live.twitch.tv/app"
    
    if [ ! -n "$OutputKey" ]; then echo "OutputKey is not set! Can't start streaming"; exit; fi

    ffOutput="-f flv $OutputURL/$OutputKey"
    echo "$$" > $bin/ffstream.pid

    mkdir -p $logs

    $ffmpeg -hide_banner -stream_loop -1 $VideoSource -thread_queue_size 1024 $AudioSource \
    $VideoConfig $OutputConfig $AudioConfig $ffOutput |& tee -a $logs/ffstream.$now.log

    rm $bin/ffstream.pid
#######################################################################################
}




#######################################################################################
#######################################################################################

if [ -n "$1" -a -z "$2" ]; then

    # If started with arg --heartbeat, init heartbeat function #
    if [ $1 == "--heartbeat" ]; then
	    sleep 5
        heartbeat
        exit
    fi

    # If started with arg --overlay, init overlay function #
    if [ $1 == "--overlay" ]; then
        sleep 5
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
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
if ! [ -f "$bin/ffstream.pid" ]; then
     $streamer --heartbeat &
     $streamer --overlay &
     stream
fi
#######################################################################################
#######################################################################################

exit