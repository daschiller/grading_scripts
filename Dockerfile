FROM ubuntu:22.04

RUN apt-get update && apt-get install -y bc python3 python3-pip --no-install-recommends
RUN pip3 install numpy pandas tqdm matplotlib dill

COPY ./grade.sh /usr/local/bin
VOLUME /data

# matplotlib cache directory needs to be writable
ENV MPLCONFIGDIR=/tmp
ENTRYPOINT cd /data && bash
