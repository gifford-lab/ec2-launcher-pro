docker pull haoyangz/ec2-launcher-pro
docker run -i -v /cluster/ec2:/cluster/ec2 -v /etc/passwd:/root/passwd:ro \
	-v /cluster/ec2/cred:/credfile:ro \
	-v $(pwd)/example/testscript-gpu.txt:/commandfile \
	--rm haoyangz/ec2-launcher-pro python ec2run.py GPU VPN -u root -p 2 -i g2.2xlarge -a ami-763a311e
