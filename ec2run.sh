#!/bin/bash
#try cat testscript.txt | ./ec2run.sh /cluster/ec2/cred thashim@csail.mit.edu
echo "Checking ipsec tunnel"
# 172.16.0.95 is the ip for any node on the other side of the tunnel.
if ping -c 5 172.16.0.95 &> /dev/null
then
    echo "Verified tunnel alive"
    echo "Check for new ec2 image"
    docker pull haoyangz/ec2-launcher-gpu
    TMP=$(mktemp)
    echo "$(cat)" > $TMP
    echo 'executing the following command:'
    cat $TMP
    rsadir=$(cat $1 | grep rsa_key | cut -f 2 -d :)
    docker run --rm -v /etc/passwd:/root/passwd -v $(readlink -e $1):/root/cred -v $(readlink -e $rsadir):/root/rsakey -v $(readlink -e $TMP):/root/command.txt -v /cluster:/cluster -i haoyangz/ec2-launcher-gpu Rscript /root/launcher.r /root/cred /root/command.txt $(id -un) $2
    rm $TMP
    echo "SUCCESS: ec2 launched with no errors. logs will appear in /cluster/ec2/"
else
    echo "ERROR: no ipsec tunnel detected. Run sudo service ipsec restart"
fi
