#!/usr/bin/Rscript

load('state.RData')

ca = commandArgs(trailingOnly=TRUE)

comm = readLines(paste0('/root/comm-',ca[1],'.txt'))
numjobs=length(comm)

itype = 'g2.2xlarge' # 4 at a time

run_file = tempfile(pattern='runcmd',tmpdir='/cluster/ec2/tmp',fileext='.txt')
writeLines(comm,run_file)

rl=readLines('/root/user-data.txt')
rl=gsub('NUM',ca[1],rl)
rl=gsub('USER',user,rl)
rl=gsub('REALM',realm,rl)
rl=gsub('EMAIL',email,rl)
rl=gsub('AKEY',access_key_remote,rl)
rl=gsub('SKEY',secret_key_remote,rl)
rl=gsub('RUNCMD',run_file,rl)
writeLines(rl,paste0('/root/user-data-',ca[1],'.txt'))

userdatablob=paste0(system(paste0('cat /root/user-data-',ca[1],'.txt | base64'),intern=T),collapse='')

lspec = paste0("\'{\"UserData\":\"",userdatablob,"\",\"ImageId\":\"",ami,"\",\"KeyName\":\"",keyname,"\",\"InstanceType\":\"",itype,"\",\"NetworkInterfaces\":[{\"DeviceIndex\":0,\"SubnetId\":\"subnet-f85957d0\",\"AssociatePublicIpAddress\":true}],\"BlockDeviceMappings\":[{\"DeviceName\":\"/dev/xvdf\",\"Ebs\":{\"VolumeSize\":10,\"DeleteOnTermination\":true}}]}\'")

launch=system(paste0('aws --region us-east-1 --output text ec2 request-spot-instances --spot-price ',price,' --type persistent --launch-specification ',lspec),intern=T)
