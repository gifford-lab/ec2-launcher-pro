# Ec2 launch scripts (for GPU jobs)
This set of scripts takes a file of (docker) jobs as input, where each line is a job,  and runs every 4 jobs on one Amazon EC2 instance `g2.8xlarge` (4 GPU) with bidding price $1.0. As the scripts are put in user-data and instance are run with "--persistent", it is fine if the instance is killed due to price fluctuation because they will be automatically relaunched when market price falls below the bidding price and a new instance get fullfilled. 

/cluster is mounted on EC2 through VPN. So the user should directly mount necessary directory of /cluster on the docker (by -v) so that it could read and write from /cluster.

All the dockers will be run as root. So please take care of permission in the input job file if you don't wish to write the output as root. (see _test.sh_ as example)

## Machine state

The default AMI is [ami-763a311e](https://github.com/BVLC/caffe/wiki/Caffe-on-EC2-Ubuntu-14.04-Cuda-7) where CUDA7 and Caffe have been preinstalled. We suggest manually create EC2 instance from web interface to make sure your code runs on this AMI before using this launcher.

/cluster of our lab cluster is mounted through VPN. In addition to the default parameters (memory / cpu etc) of a g2 machine, we also allocate 500GB of hard disk space to be attached onto /scratch.

Drive structure: (g2.2xlarge for example)

```
Filesystem            Size  Used Avail Use% Mounted on
/dev/xvda1            7.8G  4.7G  2.7G  64% /
none                  4.0K     0  4.0K   0% /sys/fs/cgroup
udev                  7.4G   12K  7.4G   1% /dev
tmpfs                 1.5G  788K  1.5G   1% /run
none                  5.0M     0  5.0M   0% /run/lock
none                  7.4G     0  7.4G   0% /run/shm
none                  100M     0  100M   0% /run/user
/dev/xvdb              64G   52M   61G   1% /mnt
10.0.11.163:/cluster  163T   98T   65T  61% /cluster
/dev/xvdf             493G  3.8G  464G   1% /scratch
```
## Usage
The input should be a _.sh_ file in which each line is a job to execute in parallel. See _test.sh_ for reference. 

We suggest the user pack all the necessary enviroment and scripts into a Docker that runs with CUDA ([example](https://github.com/Kaixhin/dockerfiles)). Otherwise, you will need to prepare an executable bash file that installs the necessary packages, prepares the environment and eventually runs the scripts. Then in the _.sh_ file input to ec2-launcher, each line should call this bash file prepared.

## Example
cat test.sh | ./ec2run.sh /cluster/zeng/private/cred.txt zeng@csail.mit.edu
