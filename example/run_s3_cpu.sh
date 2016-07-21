docker pull haoyangz/ec2-launcher-pro
docker run -i -v $(pwd)/example/testdata:/indata \
	-v /etc/passwd:/root/passwd:ro -v /cluster/ec2/cred:/credfile:ro \
	-v $(pwd)/example/testscript-s3.txt:/commandfile \
	--rm haoyangz/ec2-launcher-pro python ec2run.py CPU S3 -p 3 -b zengtest -ru test
