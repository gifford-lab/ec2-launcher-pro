docker run -i -v /cluster/zeng/code/research/mri-wrapper/example/:/indata \
	-v /etc/passwd:/root/passwd:ro -v /cluster/ec2/cred:/credfile:ro \
	-v /cluster/zeng/code/research/ec2-launcher-test/example/testscript-s3-gpu.txt:/commandfile \
	--rm haoyangz/ec2-launcher-pro python ec2run.py GPU S3 -p 0.25 -i g2.2xlarge -a ami-763a311e -b zengtest -ru test
