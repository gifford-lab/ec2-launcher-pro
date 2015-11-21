#!/usr/bin/env python
#
# ./ec2run.py old-user-data.txt /cluster/ec2/cred testscript.txt -p 1.0
#
import sys, os, argparse, pwd, base64, tempfile, subprocess, shutil

# Parse a credentials file, which is just a colon-separated series of
# lines that denote key-value pairs.  Comments are ignored, and a
# dictionary is returned that maps the names to the values.
def parse_cred_file(fin):
    ret = {}
    # Reset the file, since we might have already called this method.
    fin.seek(0)
    for line in fin:
        if line.startswith("#"): continue
        line = line.strip().split(":")
        if len(line) < 2: continue
        ret[line[0].strip()] = line[1].strip()
    return ret

# Assembles the userdata string from various arguments.
def make_userdata(args):

    userdata = args.userdata.read()

    params = {"NUM" : args.index,
              "USER" : args.user,
              "REALM" : args.region,
              "EMAIL" : args.email,
              "SEND_EMAIL" : 'true' if args.email!="" else 'false',
              "AKEY" : args.remote_access_key,
              "SKEY" : args.remote_secret_key,
              "GPUMODE_PARAM" : args.gpumode,
              "BUCKET_NAME" : args.bucket,
              "RUN_NAME" : args.runname,
              "RUNCMD" : args.command}

    # Replace keywords in the template using the existing approach.
    for keyword, value in params.iteritems():
        userdata = userdata.replace(keyword, value)

    #print userdata
    return userdata

# Make the aws client command string.
def make_aws_command(args):
    lspec_params = {"userdatablob" : base64.b64encode(make_userdata(args)),
                    "ami" : args.ami,
                    "subnet" : args.subnet,
                    "keyname" : args.keyname,
                    "itype" : args.itype,
                    "volumesize" : args.volsize}

    # Open and close braces are doubled to escape string formatting.
    lspec = """
    '{{"UserData":"{userdatablob}",
    "ImageId":"{ami}",
    "KeyName":"{keyname}",
    "InstanceType":"{itype}",
    "NetworkInterfaces":[{{"DeviceIndex":0,"SubnetId":"{subnet}","AssociatePublicIpAddress":true}}],
    "BlockDeviceMappings":[{{"DeviceName":"/dev/xvdf","Ebs":{{"VolumeSize":{volumesize},"DeleteOnTermination":true}}}}]
    }}'
    """.strip().replace("\n", "").replace(" ", "").format(**lspec_params)

    cmd_params = {"lspec" : lspec,
                  "region" : args.region,
                  "price" : args.price}

    cmd = ("aws --region {region} --output text " +
           "ec2 request-spot-instances --spot-price {price} " +
           "--type persistent --launch-specification {lspec}").format(**cmd_params)

    return cmd

def parse_args():
    parser = argparse.ArgumentParser(description="Launch a list of commands on EC2.")
    user = pwd.getpwuid(os.getuid())[0]

    # Positional (unnamed) arguments:
    parser.add_argument("mode",  type=str, help="Running model (GPU/CPU)")
    parser.add_argument("connection",  type=str, help="connection type (VPN/S3)")
    #parser.add_argument("userdata", type=argparse.FileType("r"), help="Userdata file to user as a template.")
    #parser.add_argument("credfile", type=argparse.FileType("r"), help="Credentials file.")
    #parser.add_argument("commandfile", default="-", nargs="?", type=argparse.FileType("r"), help="Command file (default stdin).")

    # Optional arguments:
    parser.add_argument("-a", "--ami", dest="ami", default="ami-864d84ee", help="Target AMI (default 864d84ee).")
    parser.add_argument("-s", "--subnet", dest="subnet", default="subnet-f85957d0", help="VPN (?) subnet.")
    parser.add_argument("-i", "--itype", dest="itype", default="r3.xlarge", help="Instance type (default r3.xlarge).")
    parser.add_argument("-k", "--keyname", dest="keyname", default="starcluster", help="Keyname (default starcluster; credential file overrides this).")
    parser.add_argument("-r", "--region", dest="region", default="us-east-1", help="EC2 region (default us-east-1).")
    parser.add_argument("-p", "--price", dest="price", type=float, default=0.34, help="Spot bid price (default 0.34).")
    parser.add_argument("-u", "--user", dest="user", default=user, help="User (default is $USER).")
    parser.add_argument("-e", "--email", dest="email",default="", help="Email address to send and get notification")
    parser.add_argument("-n", "--splitsize", dest="splitsize", type=int, default=1, help="Number of commands per instance (default 1).")
    parser.add_argument("-b", "--bucket", dest="bucket", default="", help="The S3 bucket for data transfer (for S3 mode only)")
    parser.add_argument("-ru", "--runname", dest="runname", default="", help="The S3 runname for data transfer (for S3 mode only)")
    parser.add_argument("-v", "--volumesize", dest="volsize", type=int,default=500, help="The size (in GB) of hard disck (/scratch) added to each EC2 instance (default 500)")

    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    if args.mode == 'CPU':
        args.gpumode = 'false'
    elif args.mode == 'GPU':
        args.gpumode = 'true'
    else:
        print 'ERROR: Unrecognized mode: ' + args.mode
        sys.exit(1)

    args.credfile = open('/credfile')
    args.commandfile = open('/commandfile')

    # Set up enviroment for running awscli
    creds = parse_cred_file(args.credfile)
    args.access_key = creds['access_key']
    args.secret_key = creds['secret_key']
    if creds.has_key("rsa_key"):
        args.keyname = os.path.splitext(os.path.basename(creds["rsa_key"]))[0]
    os.system('mkdir ~/.aws')
    os.system(''.join(['printf \"[default]\naws_access_key_id=',args.access_key,'\naws_secret_access_key=',args.secret_key,'\" > ~/.aws/config']))

    if args.connection == 'VPN':
        args.userdata = 'user-data.txt'
        # Update the passwd file on /cluster/ec2 so that the EC2 nodes can
        # have up-to-date information (they grab it in the user-data
        # script).
        try:
            shutil.copyfile("/root/passwd", "/cluster/ec2/passwd")
        except IOError:
            print >>sys.stderr, "Warning: failed to update /cluster/ec2/passwd"

        # The directory to store the running commands for each instance
        runcmd_dir = "/cluster/ec2/tmp"

        args.remote_access_key = creds['access_key_remote']
        args.remote_secret_key = creds['secret_key_remote']
    elif args.connection == 'S3':
        args.userdata = 'user-data-s3.txt'
        args.inputdir = "/indata"
        assert args.bucket != ""
        assert args.runname != ""
        os.system(' '.join(['aws s3 mb s3://'+args.bucket]))
        os.system(' '.join(['aws s3 rm s3://'+args.bucket+'/'+args.runname+'/runcmd/','--recursive']))
        os.system(' '.join(['aws s3 rm s3://'+args.bucket+'/'+args.runname+'/input/','--recursive']))
        os.system(' '.join(['aws s3 rm s3://'+args.bucket+'/'+args.runname+'/output/','--recursive']))
        os.system(' '.join(['aws s3 rm s3://'+args.bucket+'/'+args.runname+'/runparams/','--recursive']))
        os.system(' '.join(['aws s3 rm s3://'+args.bucket+'/'+args.runname+'/log/','--recursive']))
        os.system(' '.join(['aws s3 cp --recursive',args.inputdir, 's3://'+args.bucket+'/'+args.runname+'/input/']))
        os.system(' '.join(['aws s3 cp /root/passwd s3://'+args.bucket+'/'+args.runname+'/runparams/']))
        runcmd_dir = "tmp"
        os.makedirs(runcmd_dir)

        args.remote_access_key = args.access_key
        args.remote_secret_key = args.secret_key

    else:
        print 'ERROR: Unrecognized connection type: ' + args.connection
        sys.exit(1)

    args.userdata = open(args.userdata)

    commands = args.commandfile.readlines()

    # Launch the commands in batches of size splitsize (by line).
    runstr = open('runstr.txt','w')
    for index in xrange(0, len(commands) / args.splitsize):
        command = commands[index * args.splitsize : (index+1) * args.splitsize]
        command = [s.strip() for s in command]
        args.index = str(index+1)

        cmd_file = tempfile.NamedTemporaryFile(dir=runcmd_dir,
                                         suffix=".txt",
                                         prefix="runcmd_",
                                         delete=False)
        cmd_file.writelines("\n".join(command))
        cmd_file.flush()
        cmd_file.close()
        os.system('chmod 644 ' + cmd_file.name)
        if args.connection == 'S3':
            os.system(' '.join(['aws s3 cp',cmd_file.name,' s3://'+args.bucket+'/'+args.runname+'/runcmd/']))

        args.command = os.path.basename(cmd_file.name)
        cmd = make_aws_command(args)
        print ">> launching batch %s: %s" % (args.index, command)
        runstr.write('%s\n' % cmd)

    runstr.close()
    os.system('cat runstr.txt | parallel -j 16')
    os.system('cat runstr.txt')
    args.userdata.close()
    args.credfile.close()
    args.commandfile.close()
