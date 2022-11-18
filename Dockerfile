FROM ubuntu:22.04

RUN apt-get update && apt-get install -y bc less python3 python3-pip --no-install-recommends
#COPY requirements.txt /tmp/requirements.txt
#RUN pip3 install -r /tmp/requirements.txt
#RUN pip3 install ipython ipdb

COPY ./grade*.sh /usr/local/bin/
VOLUME /data

# matplotlib cache directory needs to be writable
ENV MPLCONFIGDIR=/tmp
ENTRYPOINT cd /data && bash
