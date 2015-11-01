#Baseline
FROM ubuntu:14.04

MAINTAINER Haoyang Zeng <haoyangz@mit.edu>

RUN sudo apt-get update
RUN sudo apt-get -q -y install r-base openssh-client python-pip
RUN sudo pip install awscli
RUN sudo apt-get -q -y install parallel

RUN mkdir /scripts
ADD ec2run.py /scripts/
ADD user-data.txt /scripts/
ADD user-data-s3.txt /scripts/
WORKDIR /scripts
RUN chmod 777 /scripts

