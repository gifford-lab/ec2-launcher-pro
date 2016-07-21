docker pull haoyangz/ec2-launcher-pro
docker run -i -v $(pwd)/example/testdata/:/indata \
	-v /etc/passwd:/root/passwd:ro -v /cluster/ec2/cred:/credfile:ro \
	-v $(pwd)/example/testscript-s3-gpu.txt:/commandfile \
	--rm haoyangz/ec2-launcher-pro python ec2run.py GPU S3 -p 0.25 \
	-i g2.2xlarge -a ami-763a311e -b zengtest -ru test
