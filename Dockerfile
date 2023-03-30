FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bc less python3 python3-pip python-is-python3
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt
RUN pip3 install ipython ipdb

COPY ./grade*.sh /usr/local/bin/
VOLUME /data

# matplotlib cache directory needs to be writable
ENV MPLCONFIGDIR=/tmp
ENV LC_ALL=C.UTF-8
WORKDIR /data
ENTRYPOINT bash
