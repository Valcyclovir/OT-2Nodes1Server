#!/bin/bash

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
    source "/etc/otnode/config.sh"
else
    #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
    source "/root/OT-2Nodes1Server/config.sh"
fi

HOST=$(hostname)
MESSAGE="${HOST^}: $@"
URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"

curl -s -d "chat_id=$CHAT_ID&disable_web_page_preview=1&text=$MESSAGE" "$URL" > /dev/null