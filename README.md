A tool that lauches docker jobs on Amazon EC2 cloud instances (machines).

## Dependencies
You will need to pack your software in [Docker](www.docker.com) and make it available on [Docker Hub](hub.docker.com). We support running nvidia-docker.

## Connection Mode
Two connection modes are provided: VPN and S3. 

+ For **Gifford lab only**, the VPN mode establish a direct connection between /cluster and the EC2 instance through a VPN. With this model, the user can access /cluster on EC2 instance as if you are physically running on the cluster.

+ For **general users**, the S3 mode is the only choice. In this model, the input data will be automatically uploaded to S3 storage and all the output will also be dumped to S3. The user will need to manually retrieve the output from S3 if needed.

## Example Usage

#### VPN mode 

Quick examples to run them under **repository directory**: [CPU job](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/run_vpn_cpu.sh), [GPU job](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/run_vpn_gpu.sh)

First check if the VPN is up by running the following on **sox2**:

```
if ping -c 5 172.16.0.95 &> /dev/null
then
    echo 'VPN is up!'
else
    echo 'VPN is not ready...'
fi

```

Then 

```
docker pull haoyangz/ec2-launcher-pro
docker run -i -v /cluster/ec2:/cluster/ec2 -v /etc/passwd:/root/passwd:ro \
	-v CREDFILE:/credfile:ro -v RUNFILE:/commandfile \
	--rm haoyangz/ec2-launcher-pro \
	python ec2run.py MODE VPN 
```
+ `MODE`: CPU or GPU
+ `CREDFILE`: The absolute path to a file containing credential information of your Amazon AWS account. Gifford lab member can use /cluster/ec2/cred . More information please read [here](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/cred_tutorial/credfile.md).
+ `RUNFILE`: The absolute path to a file containing bash commands (usually `docker run` commands) to run. Each line should be one complete bash command which will be run as one job (process). To specify the number of jobs per EC2 instance, checkout the "Option" section below. If needed, multiple bash commands can be concatenated into oneline seperated by ";" and they will be sequentially executed. (example:[CPU](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/testscript.txt)
  [GPU](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/testscript-gpu.txt))

#### S3 mode 
Quick examples to run them under **repository directory**: [CPU jobs](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/run_s3_cpu.sh), [GPU jobs](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/run_s3_gpu.sh)

```
docker pull haoyangz/ec2-launcher-pro
docker run -i -v DATADIR:/indata -v /etc/passwd:/root/passwd:ro \
	-v CREDFILE:/credfile:ro -v RUNFILE:/commandfile \
	--rm haoyangz/ec2-launcher-pro \
	python ec2run.py MODE S3 -b BUCKETNAME -ru RUNNAME
```
+ `DATADIR`: The absolute directory of the input data. All the subfolder of this directory will be recursively copied to $BUCKETNAME$/$RUNNAME$/input on S3 and then to /scratch/input on the EC2 instance. Therefore, configure your commands in RUNFILE to get data from /scratch/input.
+ `CREDFILE`: Same as in VPN mode.
+ `RUNFILE`: Similar to that in VPN mode. *Note* You should configure your commands in RUNFILE to output to /scratch/output, all the contents of which will be copied to S3 folder $BUCKETNAME$/$RUNNAME$/output when finished. (example:[CPU](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/testscript-s3.txt)[GPU](https://github.com/gifford-lab/ec2-launcher-pro/blob/master/example/testscript-s3-gpu.txt)) 
+ `MODE`: CPU or GPU
+ `BUCKETNAME`: The S3 bucket to store the input and output.  **(required)**
+ `RUNNAME`: The subfolder of S3 bucket to store the input and output. So all the data will be under $BUCKETNAME$/$RUNNAME$ on S3.  **(required)**


## Options
Run the following command to get the full list of options:

```
python ec2run.py -h
```

which will output the following:


```
positional arguments:
  mode                  Running model (GPU/CPU)
  connection            connection type (VPN/S3)

optional arguments:
  -h, --help                            show this help message and exit
  -a AMI, --ami AMI                     Target AMI (default ami-0565af6e282977273 for CPU mode, and ami-060865e8b5914b4c4 for GPU mode).
  -s SUBNET, --subnet SUBNET            VPN (?) subnet.
  -i ITYPE, --itype ITYPE               Instance type (default r3.xlarge for CPU mode, and g3s.xlarge for GPU mode).
  -k KEYNAME, --keyname KEYNAME         Keyname (default starcluster; credential file overrides this).
  -r REGION, --region REGION            EC2 region (for S3 mode only, default us-east-1).
  -p PRICE, --price PRICE               Spot bid price (default 0.34).
  -u USER, --user USER                  User (for VPN mode only, default is $USER).
  -e EMAIL, --email EMAIL               Email address to send and get notification
  -n SPLITSIZE, --splitsize SPLITSIZE   Number of commands per instance (default 1).
  -b BUCKET, --bucket BUCKET            The S3 bucket for data transfer (for S3 mode only)
  -ru RUNNAME, --runname RUNNAME        The S3 runname for data transfer (for S3 mode only)
  -z ZONE, --zone ZONE                  The specific EC2 zone to launch in (for S3 mode only, default to let EC2 choose)
  -v VOLSIZE, --volumesize VOLSIZE      The size (in GB) of hard disck (/scratch) added to each EC2 instance (default 500)
```

#### Commonly tweakable options (Default value can be found above)
+ `AMI`: Choose the right OS that matches your usage. The default AMI for GPU mode is ami-060865e8b5914b4c4 which has CUDA10.0. For other versions, check out the EC2 AMI marketplace.
+ `ITYPE` Choose the right machine [type](https://aws.amazon.com/ec2/instance-types/) that matches your usage. 
+ `PRICE`: In EC2 console, check out "Pricing History" under "Instances" -> "Spot Requests" for a good price for your region and instance type.
+ `EMAIL`:  If an address is provided, a notification email will be sent from this address to itself every time an EC2 instance finishes. This address has to be added to the list of "verified sender" in your EC2 Simple Email Service console.
+ `SPLITSIZE`: This number of jobs will be running in parallel in one instance.
+ `VOLSIZE`: The size should be large enough to store all the input needed and output generated by all the jobs on that instance. On the other hand, with too many instances launched, the total volume might exceed the limit for Magnetic volume storage for your EC2 account. Find out the limit of your account in the console by "Limits" - > "EBS Limits" -> "Magnetic volume storage".

#### VPN mode only (Default value can be found above)
+ `USER`: The commands in `RUNFILE` will read and write data on /cluster as this user. The default is to run as current user. 

#### S3 mode only (Default value can be found above)
+ `REGION`: This is only tweakable for S3 mode as VPN is only built on us-east-1.
+ `ZONE`: The specific zone in which you wish to launch your instance, for example us-east-1a. Default is to let EC2 choose from all zones under `REGION` you specified based on availability.
+ `BUCKET`: The S3 bucket to store the input and output.  **(required, no defalt value)**
+ `RUNNAME`: The S3 folder in the bucket to store the input and output.  **(required, no defalt value)**

