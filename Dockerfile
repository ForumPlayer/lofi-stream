FROM debian:stable-slim
LABEL maintainer="ForumPlayer"

EXPOSE 4887/tcp
EXPOSE 6600/tcp

RUN useradd -u 106 -g 29 -d /mpd -N mpd

RUN apt update && apt install htop nano mpd mpc ncmpcpp ffmpeg -y                                                                                                                                                  
RUN mkdir -p /run/mpd && chown -cR mpd:audio /run/mpd                                                                                                                                                              

WORKDIR /mpd
COPY . /mpd

RUN chown -cR mpd:audio /mpd
RUN mv mpd.conf /etc/mpd.conf
RUN chmod +x /mpd/bin/*

USER mpd
CMD ["/mpd/bin/init.sh"]
