#!/bin/bash

# After OT node update, you must run this to all your nodes to set arangod variables compatible with multidocker setup.

# Define all values before running this script. The default values are the ones I have tested personally and have yielded the best results.


# --rocksdb.write-buffer-size
# The amount of data to build up in each in-memory buffer (backed by a log file) before closing the buffer and queuing it to be flushed into standard storage. 
# Default: 64MiB. Larger values may improve performance, especially for bulk loads.

# --rocksdb.total-write-buffer-size
# The total amount of data to build up in all in-memory buffers (backed by log files). This option, together with the block cache size configuration option, can be used to limit memory usage.
# If set to 0, the memory usage is not limited.
# If set to a value larger than 0, this will cap memory usage for write buffers but may have an effect on performance.
# If there is less than 4GiB of RAM on the system, the default value is 512MiB. If there is more, the default is (system RAM size - 2GiB) * 0.5.

# --rocksdb.max-total-wal-size
# Maximum total size of WAL files that, when reached, will force a flush of all column families whose data is backed by the oldest WAL files. 
# Setting this to a low value will trigger regular flushing of column family data from memtables, so that WAL files can be moved to the archive. 
# Setting this to a high value will avoid regular flushing but may prevent WAL files from being moved to the archive and being removed.

# --rocksdb.max-write-buffer-number
# The maximum number of write buffers that built up in memory. If this number is reached before the buffers can be flushed, writes will be slowed or stalled. 
# Default: 2.

# --rocksdb.dynamic-level-bytes
# If true, the amount of data in each level of the LSM tree is determined dynamically so as to minimize the space amplification; otherwise, the level sizes are fixed. 
# The dynamic sizing allows RocksDB to maintain a well-structured LSM tree regardless of total data size. Default: true.

# --rocksdb.block-cache-size
# This is the maximum size of the block cache in bytes. Increasing this may improve performance. 
# If there is less than 4GiB of RAM on the system, the default value is 256MiB. If there is more, the default is (system RAM size - 2GiB) * 0.3.

# Team values :
# --rocksdb.write-buffer-size 2048000 
# --rocksdb.total-write-buffer-size 81920000 
# --rocksdb.max-total-wal-size 1024000 
# --rocksdb.max-write-buffer-number 2 
# --rocksdb.dynamic-level-bytes false

# Values :
# write_buffer_size=67108864
# total_write_buffer_size=536870912
# max_total_wal_size=1024000
# max_write_buffer_number=2
# dynamic_level_bytes=true
# block_cache_size=268435456

version=5.1.2
write_buffer_size=67108864
total_write_buffer_size=536870912
#max_total_wal_size=1024000
max_write_buffer_number=2
dynamic_level_bytes=true
block_cache_size=536870912
server_statistics=false

if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
fi

source "$MAINPATH/data/fixed-variables.sh"

for (( i=$NODE_COUNTER; i<=$NODE_TOTAL; i++ ))
do
  NODE="$NODE_NAME$i"

  echo "changing arangod vars to be compatible with MN docker"

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/init/testnet/supervisord.conf" ]; then
    sed -i 's/command=arangod.*/command=arangod --rocksdb.write-buffer-size '$write_buffer_size' --rocksdb.total-write-buffer-size '$total_write_buffer_size' --rocksdb.max-write-buffer-number '$max_write_buffer_number' --rocksdb.dynamic-level-bytes '$dynamic_level_bytes' --rocksdb.block-cache-size '$block_cache_size' --server.statistics '$server_statistics' /g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/init/testnet/supervisord.conf
  fi

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/$version/testnet/supervisord.conf" ]; then
    sed -i 's/command=arangod.*/command=arangod --rocksdb.write-buffer-size '$write_buffer_size' --rocksdb.total-write-buffer-size '$total_write_buffer_size' --rocksdb.max-write-buffer-number '$max_write_buffer_number' --rocksdb.dynamic-level-bytes '$dynamic_level_bytes' --rocksdb.block-cache-size '$block_cache_size' --server.statistics '$server_statistics' /g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/$version/testnet/supervisord.conf
  fi

  docker update --memory=5G --memory-swap=10G $NODE
  
  echo "docker restart $NODE"
  docker restart $NODE
done
