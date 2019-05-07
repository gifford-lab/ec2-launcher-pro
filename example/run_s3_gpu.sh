docker pull haoyangz/ec2-launcher-pro
docker run -i -v $(pwd)/example/mri:/indata \
	-v /etc/passwd:/root/passwd:ro -v /cluster/ec2/cred:/credfile:ro \
	-v $(pwd)/example/testscript-s3-gpu.txt:/commandfile \
	--rm haoyangz/ec2-launcher-pro python ec2run.py GPU S3 -p 2 -b zengtest -ru test
