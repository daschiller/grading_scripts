FROM ubuntu:20.04

RUN apt-get update && apt-get install -y python3 python3-pip --no-install-recommends
RUN pip3 install numpy pandas

COPY ./grade.sh /usr/local/bin
VOLUME /data

ENTRYPOINT cd /data && bash -l
