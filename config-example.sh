######################### GLOBAL VARIABLES #########################

# BACKUP                             You have 3 options here :
#
#                                    1. RECOMMENDED - Storage VPS + Minio : This method uses s3 rather than sftp to upload backups to your storage vps which is MUCH faster.
#                                       In order to use Minio, you must fill up all six variables below as follows : 
#
# MINIO_USER                            Set the username to your minio server. Default : minio-user
# MINIO_BACKUPDIR                       Set the backup directory of your restic backups. Default : /usr/local/share/minio
#
# RESTIC_REPOSITORY (on storage vps)    export RESTIC_REPOSITORY="/usr/local/share/minio/backup" 
#                                       change /usr/local/share/minio/ depending on your choice of directory above
#                   (on node server)    export RESTIC_REPOSITORY="s3:http://STORAGE_VPS_IP_ADDRESS:9000/backup"
#
# RESTIC_PASSWORD                       Any password of your choosing. It has to be the same password as AWS_SECRET_ACCESS_KEY.
#
# AWS_ACCESS_KEY_ID                     export AWS_ACCESS_KEY_ID="minio"
# AWS_SECRET_ACCESS_KEY                 export AWS_SECRET_ACCESS_KEY="SAME_AS_RESTIC_PASSWORD"
#
#                                       Make sure you fill up this config.sh before running install-minio-storage-vps.sh on your storage VPS. 
#
#                                    2. Storage VPS only (Alwyzon, Alpha VPS, Nexus Bytes)
#                                       You must buy a storage VPS and configure it following README instructions first
#                                       Input example (on multinode server) : sftp:root@1.1.1.1:/root/backup
#                                       Input example (in your storage vps) : /root/backup
#                                       Fill up the first two variables, ignore the next 4.
#
#                                    3. Amazon AWS - not recommended, but supported
#                                       Create a new bucket and replace bucketname with the name of your bucket
#                                       Input example : s3:https://s3.amazonaws.com/bucketname
#                                       Then, input your AWS Access Key ID and Secret Access Key below
# RESTIC_PASSWORD                    Use your desired password, do not forget it ! Use the same password on AWS_SECRET_ACCESS_KEY if you are using storage VPS + Minio.

export RESTIC_REPOSITORY="s3:http://STORAGE_VPS_IP_ADDRESS:9000/backup"
export RESTIC_PASSWORD="REPLACE_WITH_RESTIC_REPOSITORY_PASSWORD_OF_YOUR_CHOICE"

export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

export MINIO_USER=""
export MINIO_BACKUPDIR=""

# NUMBERRESTICSNAPSHOTS              Number of snapshots to keep when performing restic-cleanup.sh

NUMBERRESTICSNAPSHOTS="1"

# TELEGRAM_TOKEN                     Add @botfather on telegram. Follow the instructions to create your own chat bot.
# CHAT_ID                            Add @myidbot to telegram. Type /begin. It will tell you your chat ID.

export TELEGRAM_TOKEN="REPLACE_WITH_TELEGRAM_TOKEN"
export CHAT_ID="REPLACE_WITH_TELEGRAM_CHAT_ID"

# MAINPATH                           Path to OT-2Nodes1Server repository. Paths don't change if using the default path.
# BACKUPPATH                         The path where you want your backups to reside temporarily
# NODEBASEPATH                       The path for the node main folder (containing .origintrail_noderc)

export MAINPATH="/root/OT-2Nodes1Server"
export BACKUPPATH="/root/backup"
export NODEBASEPATH="/root"

# BID_CHECK_JOB_NOTIFY_ENABLED       Set to false to disable bid notifications (default true)
# PRUNING_NOTIFY_ENABLED             Set to false to disable pruning notifications (default true)
# BID_CHECK_INTERVAL_DOCKER          Set this to how far back to search the log for mentions of "Accepting" (default 60 minutes).
# NOTIFY_ON_SUCCESS                  Set to false to disable backup success notifications (default true)

BID_CHECK_INTERVAL_DOCKER="60m"
BID_CHECK_JOB_NOTIFY_ENABLED="true"
PRUNING_NOTIFY_ENABLED="true"
BACKUP_NOTIFY_ON_SUCCESS="true"

# SPACE_THRESHOLD                    Set this to what percentage it should alert above (default 90%).

DISK_CHECK_THRESHOLD="90"

###################### MULTINODE CONFIGURATION ######################

# NODE_TOTAL                         Set the total amount of docker nodes your server is expected to have after your session
#                                    If you have 2 nodes in your server now and want to add 4 more, NODE_TOTAL=6
#                                    If you have 0 node and want to add 5, NODE_TOTAL=5

# NODE_COUNTER                       Default value=1. NODE_COUNTER is the value of the next node in line, and starts at 1
#                                    For instance, if you already have 2 nodes and want to add 8 more, NODE_COUNTER=3
#                                    Remember to update NODE_TOTAL to reflect the total amount of nodes you will end up with
#                                    For the example right above, NODE_TOTAL=10
                              
# NODE_NAME                          Set the node name that all nodes will share here, be careful, it is case sensitive. Example: otnode

# IMPORTANT                          If you want to migrate two old nodes, you need to place the backup files inside /root/backup1 and /root/backup2 respectively      
#                                    Later on, if you want to migrate two extra nodes to your current multinode server, you must put their backup files
#                                    inside /root/backup3 /root/backup4 and so on. Make sure you follow the order.  

# IMPORTANT                          You must change NODE_TOTAL and NODE_COUNTER every time you add new nodes. 

NODE_TOTAL="TOTAL_NODES_YOUR_SERVER_WILL_HAVE"
NODE_COUNTER="1"
NODE_NAME="NODE_NAME_HERE"

################# ORIGINTRAIL_NODERC CONFIGURATION #################

# MANAGEMENT_WALLET                 Set the public address of your cold storage wallet
# DH_PRICE_FACTOR                   Set the lambda value for your node (default: 0.05)
# AUTO_UPDATER                      Set automatic OriginTrail updates to true or false. If false, updates only happen when you turn it back to true. Recommended : false
# DATASET_PRUNING                   Set pruning of dataset to true or false. This is the V1 pruning. 
# PRUNE_LOW_VALUE_DATASETS          Set pruning for low estimated value datasets to true or false. If true, data graphs for which a node is not a designated DH node 
#                                   and are closest to expiry date will start to get pruned at whatever percentage is specified in MINIMUM_FREE_SPACE_PERCENTAGE
#MINIMUM_FREE_SPACE_PERCENTAGE	    Set percentage at which low estimated value datasets start getting pruned		    

MANAGEMENT_WALLET="INPUT_VARIABLE_HERE"
DH_PRICE_FACTOR="0.05"
AUTO_UPDATER="false"
DATASET_PRUNING="true"
PRUNE_LOW_VALUE_DATASETS="true" 
MINIMUM_FREE_SPACE_PERCENTAGE="50"

# BLOCKCHAIN_IMPLEMENTATIONS        Set active blockchain. Write the blockchains in parenthesis. Choose between : (eth) (xdai) (matic) (eth xdai) (xdai matic) etc.
# NODE_WALLET                       Set your operational public wallet address
# NODE_PRIVATE_KEY                  Set your operational private wallet address
# RPC_SERVER_URL                    Set your RPC URL using the following format : "https://mainnet.infura.io/v3/XXXXXXXXXXXXXX". Ignore this section if you have no ETH node.
# INITIAL_DEPOSIT_AMOUNT            Set your initial TRAC amount. For 5000 TRAC, input 5000000000000000000000
# HOSTNAME                          Set your subdomain address. You cannot use IP addresses for multinodes. Example : ot1.server1.otnode.com
# DH_MAX_HOLDING_TIME_IN_MINUTES    Set the maximum job term. To accept 5 year jobs, input 2630000

# NODE 1
BLOCKCHAIN_IMPLEMENTATIONS_1=(INPUT_VARIABLE_HERE)
NODE_WALLET_1="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_1="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_1="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_1="INPUT_VARIABLE_HERE"
HOSTNAME_1="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_1="INPUT_VARIABLE_HERE"

# NODE 2
BLOCKCHAIN_IMPLEMENTATIONS_2=(INPUT_VARIABLE_HERE)
NODE_WALLET_2="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_2="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_2="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_2="INPUT_VARIABLE_HERE"
HOSTNAME_2="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_2="INPUT_VARIABLE_HERE"

# NODE 3
BLOCKCHAIN_IMPLEMENTATIONS_3=(INPUT_VARIABLE_HERE)
NODE_WALLET_3="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_3="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_3="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_3="INPUT_VARIABLE_HERE"
HOSTNAME_3="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_3="INPUT_VARIABLE_HERE"

# NODE 4
BLOCKCHAIN_IMPLEMENTATIONS_4=(INPUT_VARIABLE_HERE)
NODE_WALLET_4="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_4="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_4="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_4="INPUT_VARIABLE_HERE"
HOSTNAME_4="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_4="INPUT_VARIABLE_HERE"

# NODE 5
BLOCKCHAIN_IMPLEMENTATIONS_5=(INPUT_VARIABLE_HERE)
NODE_WALLET_5="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_5="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_5="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_5="INPUT_VARIABLE_HERE"
HOSTNAME_5="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_5="INPUT_VARIABLE_HERE"

# NODE 6
BLOCKCHAIN_IMPLEMENTATIONS_6=(INPUT_VARIABLE_HERE)
NODE_WALLET_6="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_6="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_6="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_6="INPUT_VARIABLE_HERE"
HOSTNAME_6="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_6="INPUT_VARIABLE_HERE"

# NODE 7
BLOCKCHAIN_IMPLEMENTATIONS_7=(INPUT_VARIABLE_HERE)
NODE_WALLET_7="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_7="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_7="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_7="INPUT_VARIABLE_HERE"
HOSTNAME_7="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_7="INPUT_VARIABLE_HERE"

# NODE 8
BLOCKCHAIN_IMPLEMENTATIONS_8=(INPUT_VARIABLE_HERE)
NODE_WALLET_8="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_8="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_8="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_8="INPUT_VARIABLE_HERE"
HOSTNAME_8="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_8="INPUT_VARIABLE_HERE"

# NODE 9
BLOCKCHAIN_IMPLEMENTATIONS_9=(INPUT_VARIABLE_HERE)
NODE_WALLET_9="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_9="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_9="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_9="INPUT_VARIABLE_HERE"
HOSTNAME_9="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_9="INPUT_VARIABLE_HERE"

# NODE 10
BLOCKCHAIN_IMPLEMENTATIONS_10=(INPUT_VARIABLE_HERE)
NODE_WALLET_10="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_10="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_10="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_10="INPUT_VARIABLE_HERE"
HOSTNAME_10="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_10="INPUT_VARIABLE_HERE"

# NODE 11
BLOCKCHAIN_IMPLEMENTATIONS_11=(INPUT_VARIABLE_HERE)
NODE_WALLET_11="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_11="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_11="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_11="INPUT_VARIABLE_HERE"
HOSTNAME_11="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_11="INPUT_VARIABLE_HERE"

# NODE 12
BLOCKCHAIN_IMPLEMENTATIONS_12=(INPUT_VARIABLE_HERE)
NODE_WALLET_12="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_12="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_12="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_12="INPUT_VARIABLE_HERE"
HOSTNAME_12="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_12="INPUT_VARIABLE_HERE"

# NODE 13
BLOCKCHAIN_IMPLEMENTATIONS_13=(INPUT_VARIABLE_HERE)
NODE_WALLET_13="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_13="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_13="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_13="INPUT_VARIABLE_HERE"
HOSTNAME_13="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_13="INPUT_VARIABLE_HERE"

# NODE 14
BLOCKCHAIN_IMPLEMENTATIONS_14=(INPUT_VARIABLE_HERE)
NODE_WALLET_14="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_14="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_14="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_14="INPUT_VARIABLE_HERE"
HOSTNAME_14="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_14="INPUT_VARIABLE_HERE"

# NODE 15
BLOCKCHAIN_IMPLEMENTATIONS_15=(INPUT_VARIABLE_HERE)
NODE_WALLET_15="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_15="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_15="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_15="INPUT_VARIABLE_HERE"
HOSTNAME_15="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_15="INPUT_VARIABLE_HERE"

# NODE 16
BLOCKCHAIN_IMPLEMENTATIONS_16=(INPUT_VARIABLE_HERE)
NODE_WALLET_16="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_16="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_16="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_16="INPUT_VARIABLE_HERE"
HOSTNAME_16="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_16="INPUT_VARIABLE_HERE"

# NODE 17
BLOCKCHAIN_IMPLEMENTATIONS_17=(INPUT_VARIABLE_HERE)
NODE_WALLET_17="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_17="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_17="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_17="INPUT_VARIABLE_HERE"
HOSTNAME_17="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_17="INPUT_VARIABLE_HERE"

# NODE 18
BLOCKCHAIN_IMPLEMENTATIONS_18=(INPUT_VARIABLE_HERE)
NODE_WALLET_18="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_18="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_18="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_18="INPUT_VARIABLE_HERE"
HOSTNAME_18="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_18="INPUT_VARIABLE_HERE"

# NODE 19
BLOCKCHAIN_IMPLEMENTATIONS_19=(INPUT_VARIABLE_HERE)
NODE_WALLET_19="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_19="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_19="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_19="INPUT_VARIABLE_HERE"
HOSTNAME_19="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_19="INPUT_VARIABLE_HERE"

# NODE 20
BLOCKCHAIN_IMPLEMENTATIONS_20=(INPUT_VARIABLE_HERE)
NODE_WALLET_20="INPUT_VARIABLE_HERE"
NODE_PRIVATE_KEY_20="INPUT_VARIABLE_HERE"
RPC_SERVER_URL_20="INPUT_VARIABLE_HERE"
INITIAL_DEPOSIT_AMOUNT_20="INPUT_VARIABLE_HERE"
HOSTNAME_20="INPUT_VARIABLE_HERE"
DH_MAX_HOLDING_TIME_IN_MINUTES_20="INPUT_VARIABLE_HERE"
