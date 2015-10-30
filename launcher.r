ca = commandArgs(trailingOnly=TRUE)
print(ca)
#credential file

cred.file = ca[1]
#command to execute
command = ca[2]
#email
user = ca[3]
email = ca[4]
if(length(ca)<4 | email == 'NULL'){
    email = NULL
}


####
# constants
realm = 'us-east-1'
price = 0.25
maxgpu = 1
ami = 'ami-763a311e'

rsystem <- function(sh,intern=F,wait=T,toshow=F){
    system(paste0('ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ',rsa_key,' ubuntu@',INSTANCE_NAME,' ',shQuote(sh)),intern=intern,wait=wait,ignore.stdout=toshow,ignore.stderr=toshow)
}

scptoclus <- function(infile,out,intern=F){
    system(paste0('scp -C -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -c arcfour -i ',rsa_key,' ',shQuote(infile),' ubuntu@',INSTANCE_NAME,':',shQuote(out)))
}


docker.prefix = ''
print(paste0('credential path:',cred.file))
print(paste0('command to execute: ',docker.prefix,command))
if(!is.null(email)) print(paste0('email:',email))

file.copy('/etc/passwd','/cluster/ec2/passwd')

print('parse credential file')
cf=readLines(cred.file)
cf=cf[-grep('#',cf)]
for(sp in strsplit(cf,':')){
    print(sp)
    assign(sp[1],sp[2])
}
if(!file.exists(rsa_key)){print('check rsa key is readable')}
keyname=rev(strsplit(rsa_key,'[/.]')[[1]])[2]
print('setting key name to:')
print(keyname)

tmp = paste0(tempfile(),'.rsa')
file.copy('/root/rsakey',tmp)
Sys.chmod(tmp,mode='600')
rsa_key = tmp

system('mkdir ~/.aws')
system(paste0('printf \"[default]\naws_access_key_id=',access_key,'\naws_secret_access_key=',secret_key,'\" > ~/.aws/config'))

commlist = readLines(command)

commseq = c(seq(1,length(commlist),by=maxgpu),length(commlist)+1)
commlists = lapply(1:(length(commseq)-1),function(i){
    commseq[i]:(commseq[i+1]-1)
})

save.image('state.RData')
for(commid in 1:length(commlists)){
    writeLines(commlist[commlists[[commid]]],paste0('/root/comm-',commid,'.txt'))
}

runstr=sapply(1:length(commlists),function(i){
    paste0('/root/launcher.onemachine.r ',i)
})
writeLines(runstr,'/root/runstr.txt')
print('launching in parallel:')
system('cat /root/runstr.txt | parallel -j 16')
