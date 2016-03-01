docker pull haoyangz/ec2-launcher-pro
docker run -i -v /cluster/zeng/code/research/ec2-launcher-test/testdata:/indata \
	-v /etc/passwd:/root/passwd:ro -v /cluster/ec2/cred:/credfile:ro \
	-v /cluster/zeng/code/research/ec2-launcher-test/example/testscript-s3.txt:/commandfile \
	--rm haoyangz/ec2-launcher-pro python ec2run.py CPU S3 -p 3 -b zengtest -ru test
