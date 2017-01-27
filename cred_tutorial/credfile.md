## Credential file
#### Things to prepare

- Access key and secret key of your Amazon AWS account
	
	These information should be available when you create your account. If you forget, you can create a new one following procedures described [here](gen_key.md).

- Access key and secret key that will be put on the EC2 instance for data transfer bewteen the instance and the S3 storage.

	Usually they are the same as the previous access key and secret key. But if you worry about the unlikely possibility that the EC2 instance gets hacked and your credentials get leaked, you can create an another user with full access to S3 and read-only access to EC2, and use its credential here. In this case even if the credentials get leaked, they can't be used to spawn new instances under your name.
	
- RSA key

	This is used for you to ssh to EC2 instance while it is running. To create one, follow the procedures described [here](gen_keypair.md).

#### Put the prepared information into a text file

```
access_key:ec2_access_key
secret_key:ec2_scret_key
access_key_remote:ec2_access_key_of_restricted_remote_user
secret_key_remote:ec2_secret_key_of_restricted_remote_user
rsa_key:path_to_rsa_key
```

**Important**: there shouldn't be space before and after the commas


+ `access_key` and `secret_key`: The credentials for your Amazon EC2 account. 
+ `access_key_remote` and `secret_key_remote`: The credentials that will be put on EC2 instnace.
+ `rsa_key`: The absolute path to the key-pair file used to ssh into a running EC2 instance.
