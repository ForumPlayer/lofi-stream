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
        echo "Now playing: $(mpc current)" > OverlayText.txt
        #screen -dmS "render-overlay" $0 --render-overlay
        mpc current -w > /dev/null
    done
#######################################################################################

}



function render-overlay(){
#######################################################################################

    ffmpeg=$(which ffmpeg)
    logfile=$logs/ffoverlay.err.$now.log
	echo "Now playing: $(mpc current)" > OverlayText.txt
    $ffmpeg -y -loglevel error -i background.src.gif -vf "drawtext=textfile=OverlayText.txt:x=50:y=50:fontsize=24:fontcolor=white" -c:a copy background.tmp.gif 2>$logfile
    cp background.tmp.gif background.gif
    rm background.tmp.gif OverlayText.txt
    if [ ! -s  $logfile ]; then rm $logfile; fi
#######################################################################################

}



function stream() {
#######################################################################################


    ffmpeg=$(which ffmpeg)

    VideoSourceURI="$(realpath background.gif)"
    AudioSourceURI="http://127.0.0.1:4887"
    #OverlaySourceURI="$(realpath OverlayText.txt)"
    OverlaySourceURI="$(realpath overlay.png)"

    VideoSource="-re -f gif -i $VideoSourceURI"
    AudioSource="-f ogg -i $AudioSourceURI"
    #OverlaySource="-f png_pipe -i $OverlaySourceURI"
    fps=15
    gop=$((fps*2))

    scale="1280:720"
    #scale="852:480"

    VideoConfig="-filter_complex realtime,scale=$scale,format=yuv420p"
    AudioConfig="-c:a aac -ar 48000 -b:a 128k"
    OutputConfig="-r $fps -g $gop -c:v libx264 -preset ultrafast -tune zerolatency"; #-profile:v baseline"
    #OverlayConfig="-filter_complex [0:v][1:v]overlay=0:0[0:v] -c:a copy"
    #OverlayConfig="-filter_complex [0:v]drawtext=textfile='$OverlaySourceURI':x=50:y=50:fontsize=24:fontcolor=white:reload=1[0:v]"; #-filter_complex [1:v]overlay='x=0:y=0'[0:v]"
    #OverlayConfig="-vf drawtext=textfile='$OverlaySourceURI':x=50:y=50:fontsize=24:fontcolor=white:reload=1"

    OutputURL=$(cat OutputURL)
    OutputKey=$(cat OutputKey)

    ffOutput="-f flv $OutputURL/$OutputKey"
    echo "$$" > $bin/ffstream.pid

    mkdir -p $logs
    $ffmpeg -hide_banner -stream_loop -1 $VideoSource $OverlaySource -thread_queue_size 1024 $AudioSource $VideoConfig $OverlayConfig $OutputConfig $AudioConfig $ffOutput |& tee -a $logs/ffstream.$now.log

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

    # If started with arg --render-overlay, render overlay and apply on stream #
    if [ $1 == "--render-overlay" ]; then
        render-overlay
        exit
    fi

exit
fi
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
if ! [ -f "$bin/ffstream.pid" ]; then
     stream &
     $streamer --heartbeat &
     #$streamer --overlay &
#######################################################################################
#######################################################################################
fi

exit