#Baseline
FROM ubuntu:14.04

MAINTAINER Tatsunori Hashimoto <thashim@mit.edu>

RUN sudo apt-get update
RUN sudo apt-get -q -y install r-base openssh-client python-pip
RUN sudo pip install awscli
RUN sudo apt-get -q -y install parallel

ADD launcher.r /root/launcher.r
ADD launcher.onemachine.r /root/launcher.onemachine.r
RUN chmod +x /root/launcher.onemachine.r
ADD user-data.txt /root/user-data.txt
ADD template.txt /root/template.txt

#launch me with
#docker build -t thashim/ec2-launcher .
#docker run --rm -t -v /etc/passwd:/root/passwd -v /cluster/ec2/cred:/root/cred -v /cluster/ec2/starcluster.rsa:/root/rsakey -v $(readlink -e testscript.txt):/root/command.txt -v /cluster:/cluster -i thashim/ec2-launcher /bin/bash
#Rscript /root/launcher.r /root/cred /root/command.txt thashim thashim@csail.mit.edu
