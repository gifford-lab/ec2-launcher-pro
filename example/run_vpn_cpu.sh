docker pull haoyangz/ec2-launcher-pro
docker run -i -v /cluster/ec2:/cluster/ec2 -v /etc/passwd:/root/passwd:ro \
	-v /cluster/ec2/cred:/credfile:ro \
	-v /cluster/zeng/code/research/ec2-launcher-test/example/testscript.txt:/commandfile \
	--rm haoyangz/ec2-launcher-pro python ec2run.py CPU VPN -u $(id -un) -p 5
