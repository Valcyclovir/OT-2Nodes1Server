# OT-2Nodes1Server

A complete guide to get multiple docker nodes running on the same server, also compatible with solo docker node. 

## __Prerequisites :__
### __1. VPS provider :__
This is the most crucial step to running a node. You need a VPS service provider that offers big enough storage to accommodate all your nodes. 

According to the team, each node requires 1 CPU @ 2.2Ghz and 2gb RAM, 20gb SSD space.  

However, in practice, as a general rule of thumb, I would recommend about 3gb RAM, 0.5 vCPU @ 2.2Ghz, 40gb SSD space per node. 

As of now, space is the main issue node runners are having, so we need to opt for a vps with tons of space. 

Therefore, the best options for VPS providers are : [Netcup](https://www.netcup.eu/vserver/vps.php) and [Contabo](https://contabo.com/en/vps/)

They both have their own strength and weaknesses, and given their low prices, they are services that oversell their servers, so you will notice some performance issues (CPU steal, sluggish) and disk I/O caps when you write too much with Netcup. However, both services seem to be stable and advertise servers up 99.9% of the time like any other provider. I cannot recommend one over the other since I have never tried Netcup before. I think they are both good choices to run multinode servers on, but always remember that you get what you pay for.

### __2. Subdomains :__
The __MOST__ important part of running multiple nodes in one server is using __subdomain names__ rather than ip addresses. Since most VPS providers only offer you one ipv4 address, you need to find a way to differentiate your nodes from one another. 

The cheapest way to get a new domain is going through https://www.namecheap.com/ and buying a domain for about 10$/year. 

Then, follow the instructions here : 
https://www.namecheap.com/support/knowledgebase/article.aspx/319/2237/how-can-i-set-up-an-a-address-record-for-my-domain/

Example : you buy domain name otnodelover.com, in the Advanced DNS Settings, you add a new record as follows :
- A Record | ot1.server1 |  11.22.33.44
- A Record | ot2.server1 |  11.22.33.44

In this example, your subdomain is ot1.server1.otnodelover.com which redirects traffic to to 11.22.33.44, your node's IP address. 

As you can see, ot2.server1.otnodelover.com is also pointing to the same address.

Now, By having different ports attributed to each subdomain, you have successfully created two different "identities" to differenciate your two nodes from each other.

This will allow you to use a single IP address given by your VPS provider and create as many identities as you like in order to run OT nodes. 

__IMPORTANT: if you change providers, you can reuse the subdomain name, but you must remember to adjust the IP address to your new server !__

__You must also remember to add the full address into the node config, not just ot1.server1, you must use ot1.server1.otnodelover.com !__

### __3. Backups :__

Storing backups with a separate provider is essential to any serious node runners. You need a backup plan in case your VPS provider fails, and you want your backup service provider to be different from your node VPS to have a separate point of failure. 

I strongly recommend [Alwyzon](https://www.alwyzon.com/en#pricing-storage) storage servers as they are cheap, fast and reliable. If you want to look elsewhere, [Alpha VPS](https://alphavps.com/storage-vps.html) and [Nexus Bytes](https://nexusbytes.com/storage-vps) are great alternatives. You should always look for transfer speeds of at least 1G/s to speed up backup and restore processes. 

I do not recommend using Amazon AWS backups ever since I got hit with a 90$ bill for downloading / writing too much. A single upload past the first free 15gb will cost you about 3$ ! If you have several nodes, this adds up really fast. Amazon's pay-per-use billing system is REALLY complicated and I do not recommend it. A storage VPS allows you to track your bandwidth and have no surprise charges. Alwyzon allows you to add 1tb of bandwidth for 0.90$ !

Some people might think to go with local physical backups. I do not recommend that either unless you have Internet download and upload speeds that match Alwyzon's 1Gbps. When your node goes down, you run the risk of being litigated in the next 15 minutes. You do not have the time to retrieve a 30gb upload from your local drive and rebuild a new server. Alwyzon is 5.10$ per month, pay it for peace of mind. 

Note that you must connect to your storage server using your node server by creating a new SSH key pair __without__ passphrase. Steps are explained below.

### __4. Naming schemes :__

In order to use this repository, your container names must all share the same name and end with 1,2,3,...

- Example : otnode1, otnode2, otnode3

When you want to convert backups from your old nodes over, you must also place them in order.

- Example : /root/backup1, /root/backup2, /root/backup3

__IMPORTANT :__ It is important to keep the same order for your nodes throughout the lifetime of your node on the server. For instance, the first node on your server will stay as otnode1, the second node otnode2. Never switch from otnode3 to otnode1 since this will cause conflicts with scripts that relies on their positioning to associate port numbers and restic backups / restore to them. 

You must also operate as root for this repository to work

For those running only 1 node, name your node however you like !

### __5. Initial setup :__

__Remember you need to be running operation system Ubuntu 18.04 or 20.04 !__

This is the initial setup part that applies to all node runners. Since this is a guide about hosting multiple nodes in one server, I will not cover this part in depth as it has been covered thoroughly by [__Milian's guide__](https://www.otnode.com/node-installations/docker#i-obtain-xdai-and-xtrac). 

You do not need to follow all of Milian's guide, only parts I. II. and the beginning part of III. (stop at "apt update && apt upgrade -y"). You can hop back right in here once you completed those steps.

If you chose netcup as your VPS provider, you must first install Ubuntu 20.04 as debian is their default system. Power off your server via the control panel, then navigate to Media, and look for Images on the top part of your screen. There, you can select Ubuntu 20.04 and select one big partition with os as as root partition. 

### __(OPTIONAL) Adding SSH key pairs to log into your server with [Termius](https://www.termius.com/), [Kitty](https://www.fosshub.com/KiTTY.html) or [MobaXTerm](https://mobaxterm.mobatek.net/)__

Milian's guide do not cover this part and having SSH key pairs is recommended for stronger security rather than using password-only logins to your servers. 

Here is a step-by-step guide :
1. First, download [__PuTTYgen__](https://www.puttygen.com/)
2. Open it, and click generate in order to generate a new key pair, add a password
3. Copy what's in the window, starting with ssh-rsa
4. File > Save private key, save the key to a safe location, this will be needed to log in your server every time, you can choose to import this key to Termius, Kitty or MobaXTerm for faster access on their respective application
3. Open up Termius, Kitty or MobaXTerm, log into your password protected server as root
4. If it's not created already, mkdir /root/.ssh
5. cd /root/.ssh
6. chmod 0700 ~/.ssh/
6. nano authorized_keys
7. paste the public key from PuTTYgen's window inside
8. ctrl+s, ctrl+x to leave
9. chmod 0600 ~/.ssh/authorized_keys
10. nano /etc/ssh/sshd_config
11. Find PermitRootLogin, replace by the following (remove the # sign in front): PermitRootLogin prohibit-password
12. Find PubkeyAuthentication and make sure it is set to yes (remove the # sign in front): PubkeyAuthentication yes
13. Find PasswordAuthentication and make sure it is set to no (remove the # sign in front):PasswordAuthentication no
12. ctrl+s, ctrl+x to leave
13. sudo systemctl restart ssh.service

You can now log in safely to your server with a SSH key pair. You can repeat the same steps from step 3 onward with your other servers. 

---
## __Installing this repository on your multinode server:__
```
apt install git
```
```
git clone https://github.com/Valcyclovir/OT-2Nodes1Server
```
```
cd
```
```
cd OT-2Nodes1Server
```
```
mkdir /etc/otnode/
```
```
cp -v config-example.sh /etc/otnode/config.sh
```
```
nano /etc/otnode/config.sh
```
Fill up the missing variables by following the instructions inside the file. You must also fill up the ### ORIGINTRAIL_NODERC CONFIGURATION ### part for each node you are adding to your server, even if you have their respective .origintrail_noderc files already. 

Do not fill up config-example.sh, it will not be recognized by your scripts !!

ctrl+s and ctrl+x to leave

Next, allow memory swap on your system. This step requires a reboot.
```
sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"/g' /etc/default/grub
```
```
sudo update-grub
```
```
reboot
```
## __Establishing a SSH connection to your storage VPS and setting up your storage VPS :__

If you choose to have a storage VPS for backup, this is where you will link your new multinode server to the storage VPS to perform backups eventually.

### __On your storage VPS :__

Log in with the provided credentials by the VPS provider and allow root login
```
sudo -i
```
```
nano /etc/ssh/sshd_config
```
Find PermitRootLogin, replace by the following (remove the # sign in front):
```
PermitRootLogin yes
```
ctrl+s and ctrl+x to leave
```
passwd
```
Create your desired password to log into root and press Enter.
```
sudo systemctl restart ssh.service
```
Earlier, you installed the repo to your multinode server. Now it's time to put it in your storage vps as well.
```
apt install git
```
```
git clone https://github.com/calr0x/OT-2Nodes1Server
```
Below is a cleanup script that allows your server to clean up any old backups every day at 3AM.
```
crontab -e
```
If prompted, choose #1 - nano.

paste the following (or use your own cronjob) :
```
0 3 * * * /root/OT-2Nodes1Server/restic-cleanup.sh
```
ctrl+s and ctrl+x to leave

Before you leave, add the below directory. It is where your config.sh file will eventually go to.
```
mkdir /etc/otnode/
```

### __On your new multinode VPS :__
```
ssh-keygen
```
Press enter until the keys are created. __DO NOT enter any passphrase__. Then, use the following line to copy the public key to your storage VPS. 

Change storage_vps_IP_address to your storage vps (example: root@1.1.1.1)
```
ssh-copy-id root@storage_vps_IP_address
```
Enter the password you set earlier to log into root

The below line will copy your config.sh to your storage vps
```
scp -r /etc/otnode/config.sh root@storage_vps_IP_address:/etc/otnode/config.sh
```
Now log in to your storage VPS to see whether the connection has been established successfully
```
ssh storage_server_ip_address
```
If the login was successful, you can now disable root password logins for security reasons
```
nano /etc/ssh/sshd_config
```
Find PermitRootLogin, replace by the following (remove the # sign in front):
```
PermitRootLogin prohibit-password
```
ctrl+s and ctrl+x to leave
```
sudo systemctl restart ssh.service
```
Now, you have 3 options to choose from as highlighted in the beginning of the config-example.sh comment section. You can choose to have backups using a storage VPS with minio (recommended), only a storage VPS (basic), or with Amazon AWS (not recommended). The below guide is for the recommended path - for the 2 others, read the comment section on config-example.sh.

### __Setting up minio with restic backups :__

First, you need to make sure all 6 variables on your config.sh file are filled up : RESTIC_REPOSITORY, RESTIC_PASSWORD, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, MINIO_USER, MINIO_BACKUPDIR. Read the comment section for help. 

Then, run the install-minio-storage-vps.sh script
```
cd /root/OT-2Nodes1Server/other-scripts
```
```
./install-minio-storage-vps.sh
```
Once the install is complete, check if your minio server is running
```
sudo systemctl status minio
```
If you don't see any errors, then proceed to next step on your multinode server.
```
exit
```
## __Linking storage VPS to node server :__
Back on your node server's root folder
```
cd OT-2Nodes1Server
```
```
source /etc/otnode/config.sh
```
```
./restic init
```
If all config.sh variables have been configured properly, you have now successfully linked your node server to your storage VPS to run restic backups and restores.

## __Adding cronjobs on crontab:__
On your multinode server, add these cronjobs to automate coldbrain or smoothbrain backups, monitor docker, disk space, job bids.

If you are not familiar with crontab and want to change the schedule of the cronjob, use crontab.guru to make sure you did not make a mistake !
```
crontab -e
```
paste the following (or use your own cronjob), change path if needed :
```
0 0 * * * /root/OT-2Nodes1Server/cronjob-coldbrain-backup.sh
*/60 * * * * /root/OT-2Nodes1Server/cronjob-node-monitor.sh
0 0 * * * /root/OT-2Nodes1Server/cronjob-daily-gains.sh
```
ctrl+s and ctrl+x to leave

## __(OPTIONAL) Restoring coldbrain backups to new multinode server quickly :__

If you've read through the steps so far, it means that you are willing to turn your solo nodes into a multinode server. The easiest way to do so when you are running out of space on your current node is by copying important directories directly from your old node to your new node, without duplication or storage medium in between. Restoring from AWS, depending on your node size, can take up to 4$ per restore. Creating a backup on your local drive requires double the amount of space that you are already having trouble with. Below is my proposed solution :

First, let's define your container name, otnode is used for this example. Run this on the terminal of your old node and change otnode name if needed :
```
NODE=otnode
```
Make sure your node is running for the following part.
```
docker exec $NODE supervisorctl stop all
```
Second, we need to find all folders that we need to transfer to your new multinode server
```
DATA=$(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' $NODE)/ot-node/data
```
```
ARANGODB=$(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' $NODE)/var/lib/arangodb3
```
```
ARANGODBAPPS=$(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' $NODE)/var/lib/arangodb3-apps
```
```
CONFIG=/root/.origintrail_noderc
```
Now, let's copy these files directly to your new multinode server. But before you do this, you must first add a new directory on your new server. The folder name is either /root/backup1... /root/backup2... etc. backup1 will restore into otnode1, backup2 will restore into otnode2 and so on. 

Log in to your new multinode server. For this example, we will use backup1 :
```
mkdir /root/backup1
```
Back on your old server, run :
```
scp -r $DATA $ARANGODB $ARANGODBAPPS $CONFIG root@MULTINODE_SERVER_IP_ADDRESS:/root/backup1
```
Repeat the same process with the rest of the nodes you want to migrate together, and put them in /root/backup2 /root/backup3 and so on.

Once everything is completed, you should see files backup1... backup2... backup3 in your /root folder on your new multinode server. 

Once you made sure your config.sh file is thoroughly completed, run :
```
/root/OT-2Nodes1Server/install-from-local-coldbrain-backups.sh
```

## __(OPTIONAL II) Restoring normal backups to new multinode server the team's way (slow) :__

If cold restore is not your thing and you want to stick to team's backup and restore methods, no problem ! Any script the team does will 100% work on a multinode docker setup. 

First, input your node name on the terminal :
```
NODE=NODE_NAME_HERE
```
Then, remove any old backups in your backup folder
```
rm -rf $(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' $NODE)/ot-node/backup/*
```
Then, you need to execute a normal backup using the team's script.
```
docker exec otnode $NODE scripts/backup.js --config=/ot-node/.origintrail_noderc --configDir=/ot-node/data --backupDirectory=/ot-node/backup
```
If you are running out of space, you will not be able to execute this backup and backup script will return an error. In that case, you will have to rescale your VPS to increase storage space or add a temporary volume. The increased cost will not matter since you will kill the VPS when it's completed anyway. 

Then, You will use scp -r to copy that backup file directly to your new multinode server. 
```
BACKUP=$(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' $NODE)/ot-node/backup
```
```
scp -r $BACKUP root@MULTINODE_SERVER_IP_ADDRESS:/root/backup1
```

I used the above example to put your first node on folder /root/backup1. You have to repeat the same steps for every node you want to include in your multinode server and put the backups in backup2, backup3, and so on. 

Once you are done this part, you can go back to your multinode server, fill up your config.sh, and move the backup files to backup1/ and not backup1/2021...
```
mv -v /root/backup1/* /root/backup1/
```
```
mv -v /root/backup1/202*/.origintrail_noderc /root/backup/
```
```
rm -rf /root/backup1/20*
```
```
cd OT-2Nodes1Server
```
```
./install-from-local-normal-backups.sh
```
---

## __(OPTIONAL III) SQLITE_CORRUPT BUG :__

There have been many reports of __SequelizeDatabaseError: SQLITE_CORRUPT: database disk image is malformed errors__ due to backups being done the wrong way on the system.db file. This error has nothing to do with a multinode server and affects everyone restoring from a corrupted system.db backup. 

### __To solve this :__

In this example, we are using __otnode__ as your old node's container name and __$NODE__ as the new node name.

First, log in to your old node and do the following:
```
apt install sqlite3
```
```
sqlite3 $(docker inspect --format='{{.GraphDriver.Data.UpperDir}}' otnode)/ot-node/data/system.db ".backup '/root/system.db.backup'"
```
Now let's send this properly backed up system.db to your new multinode server. Replace MULTINODE_NODE_IP before running the following line.
```
scp /root/system.db.backup root@MULTINODE_NODE_IP:"$(docker inspect --format='{{.GraphDriver.Data.UpperDir}}' $NODE)/ot-node/data/system.db.backup"
```
Now go to your new node server and define NODE:
```
NODE=MULTINODE_SERVER_NODE_NAME_HERE
```
```
docker stop $NODE
```
Before deleting the current corrupted system.db with the line below, make sure you check if system.db.backup has copied over successfully
```
ls $(docker inspect --format='{{.GraphDriver.Data.UpperDir}}' $NODE)/ot-node/data/
```
__Careful running the following line ! Make sure you are only deleting the corrupted system.db of the correct node !__
```
rm $(docker inspect --format='{{.GraphDriver.Data.UpperDir}}' $NODE)/ot-node/data/system.db
```
Now let's restore your system.db.backup to system.db
```
mv $(docker inspect --format='{{.GraphDriver.Data.UpperDir}}' $NODE)/ot-node/data/system.db.backup $(docker inspect --format='{{.GraphDriver.Data.UpperDir}}' $NODE)/ot-node/data/system.db
```
```
docker restart $NODE
```
After restarting your node, you should no longer see the SQLITE_CORRUPT error !

## __Scripts description:__

Now you may see which script suits your situation. Below is a brief description of each of them : 

__config-example__ : IMPORTANT FIRST STEP : make a copy of it to /etc/otnode/ and name it config.sh (mkdir /etc/otnode ; cp config-example.sh /etc/otnode/config.sh), then change all appropriate variables inside including node config information. ALWAYS start with this step. This is the only file you need actively modify variables inside.

__install-from-local-coldbrain-backups__ : performs a fresh multinode server install using cold backups copied over from your old servers. This is the script explained on the OPTIONAL part above. Restores your old nodes quickly to your multinode server ! 

IMPORTANT : You must place old node cold backup files on /root/backup1, /root/backup2 and so on. This method takes very little time to complete. Recommended.

__install-from-local-normal-backups__ : performs a fresh multinode server install using normal backups (from team's script) from your old servers. This is the slow but fool proof way of restoring to your new multinode server. 

IMPORTANT : You must place old node backup files on /root/backup1, /root/backup2 and so on. This method takes much longer than the one above. Not recommended.

__install-multiple-new-nodes__ : performs a fresh multinode server install with new nodes. This script will configure everything you need and create the amount of nodes you want. Again, all you need to modify is the config.sh file. 

This script assumes that you have your xTRAC ready (and some xdai for fees) on your operationnal wallet for node creation process. If you don't know how, please consult www.otnode.com for instructions. 

__update-multiple-noderc__ : This script will update your .origintrail_noderc file for all your nodes after you changed a value in your config.sh file. 

__solo-coldbrain-restic-backup__ : performs a one time cold backup to your storage vps. you must define variable NODE first. 

__solo-coldbrain-restic-restore__ : performs a one time cold restore from your storage vps. Your server name and container name must match the original one. You must also define variables NODE before running this script.

__solo-smoothbrain-restic-backup__ : performs a one time normal backup to your storage vps. you must define variable NODE first. 

__solo-smoothbrain-restic-restore__ : performs a one time hot (slow) restore from your storage vps. Your server name and container name must match the original one. You must also define variables NODE before running this script.

__cronjob-coldbrain-restic-backup__ : performs a sequential cold backup of all your nodes one at a time. This script is for use with the crontab to automate coldbrain backups of all your current nodes. A Telegram notification will be sent to you for a summary of the backup. 

__restore-from-coldbrain-restic-backups__ : performs a complete restore of all your nodes. You can adjust The amount of nodes you want to restore at once with the NODE_COUNTER and NODE_TOTAL variables in config.sh, but make sure you readjust NODE_TOTAL after the restore to the total amount of nodes in your server to not affect other scripts. 

Example: if you want to restore node#2 and node #3 in your server with 6 nodes, NODE_COUNTER=2, NODE_TOTAL=3 for the install, then readjust NODE_TOTAL=6 afterwards.

It is important to keep the order of your nodes, so if your node#2 needs to be restored on a new server, you should keep it as node#2 if you will eventually also restore node#1. 

This is also an all-in-one script that restores ALL your backups from your storage vps back to a brand new server. Use in case of emergency when you need to redeploy your nodes elsewhere quickly. 

IMPORTANT : If you ever want to restore to a new server, make sure the hostname is the same as the old server. To set hostname : 
```
hostnamectl set-hostname HOSTNAME
```
And also remember to switch your subdomain linked ip to the new VPS' ip address !

__cronjob-smoothbrain-restic-backup__ : this script is for use with the crontab to automate hot backups of all your current nodes. This script uses the team's backup script to send a backup folder to your storage vps. I highly recommend running multi-coldbrain-restic-backup instead, but if you want to follow the team's script, this is it.
The only positive thing about this script is your node can still be running while performing the backup, while multi-coldbrain-restic-backup requires your node to be turned off for about 1 minute.

__cronjob-node-monitor__ : this script is for use with the crontab to automate bid check, disk check and docker check to all your nodes. Monitors include docker check to ensure docker is still running, job bidding check to ensure your node is bidding for jobs and disk space check to warn you at 90% disk capacity. A Telegram message will give you a warning if needed. 

__restic-cleanup__ : this script is for use with the crontab to automate restic snapshots and backup data cleanups. You should add this script in the crontab of your storage vps as recommended on the instructions above. 

__insta-minio-storage-vps__ : this script installs minio to use with restic backups on your storage vps. Refer to the section above for instructions on how to install it !

__pruning__ : The pruning directory is directed towards update 5.1.1 "V2 pruning". The begin-pruning.sh script alongside cronjob-node-monitor.sh will help prune all your nodes one at a time. 

Feel free to raise any issues here or contact me on https://t.me/otnodegroup @BRX for any questions !

## __USEFUL MULTIDOCKER SPECIFIC COMMANDS:__

Follow all docker logs at once with container names on the left
```
docker ps --format='{{.Names}}' | xargs -P0 -d '\n' -n1 sh -c 'docker logs -f --since 15m "$1" | sed "s/^/$1: /"' _
```
Execute a docker restart node command to all nodes at once. You can change restart to another command such as start or stop. 
```
docker restart $(docker ps -a -q)
```
Find out how many times you've won a job on all your nodes combined in the last 48 hours. You can change the wording to look for in grep " " or the 48h duration to any words or numbers you want. Remove | wc -l at the end to see the actual text and not just the count. 
```
docker ps -q | xargs -L 1 docker logs --since 48h | grep "ve been chosen" | wc -l
```
Find the error ENOENT on all your nodes for the past 48 hours, and include 3 lines before the error and 2 lines after
```
docker ps --format='{{.Names}}' | xargs -P0 -d '\n' -n1 sh -c 'docker logs --since 48h "$1" | grep -B 3 -A 2 "ENOENT" | sed "s/^/$1: /"' _
```
The two scripts below change your jourmal mode to WAL or DELETE. WAL reduces writes on your system 3 to 5 fold. Recommended. Run the first script on your multinode server, and the second one if you want to revert back to the default mode. If you installed with the new install scripts, wal mode is already integrated in the installation process. 
```
for i in `docker ps -q`; do docker exec -it $i sqlite3 /ot-node/data/system.db 'PRAGMA journal_mode=WAL;'; done
```
```
for i in `docker ps -q`; do docker exec -it $i sqlite3 /ot-node/data/system.db 'PRAGMA journal_mode=DELETE;'; done
```
### __DONE !__
