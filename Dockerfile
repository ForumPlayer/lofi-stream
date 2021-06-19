FROM alpine:latest
LABEL maintainer="ForumPlayer"

EXPOSE 4887/tcp
EXPOSE 6600/tcp

RUN mkdir /mpd
RUN adduser -D -h /mpd mpd

RUN apk add htop nano mpd mpc ncmpcpp bash ffmpeg
RUN setcap -r /usr/bin/mpd

WORKDIR /mpd
COPY . /mpd

RUN chown -cR mpd:mpd /mpd
RUN mv mpd.conf /etc/mpd.conf
RUN chmod +x /mpd/bin/*

USER mpd
CMD ["/mpd/bin/init.sh"]