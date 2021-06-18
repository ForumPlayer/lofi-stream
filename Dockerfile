FROM alpine:latest
LABEL maintainer="ForumPlayer"

EXPOSE 4887/tcp
EXPOSE 6600/tcp

RUN apk add htop nano mpd mpc ncmpcpp bash ffmpeg
RUN setcap -r /usr/bin/mpd

RUN mkdir /stream
RUN adduser -D -h /stream stream

WORKDIR /stream
COPY . /stream

RUN mv mpd.conf /etc/mpd.conf
RUN chmod +x /stream/bin/*

USER stream
CMD ["/stream/bin/init.sh"]