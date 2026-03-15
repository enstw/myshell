#!/bin/bash

set -e
INS=default
BREWHOME="/usr/local/bin"
MACBREWHOME="/opt/homebrew/bin"

if [ -d "$MACBREWHOME" ]; then	
    BREWHOME="$MACBREWHOME"
fi

PATH=${BREWHOME}:$PATH
INSHOME=$HOME/.lima/$INS
QMPSOCK=$INSHOME/qmp.sock
QMPPORT="UNIX-CONNECT:$QMPSOCK"

if [ ! -w $QMPSOCK ]; then
    "Socket not found: $QMPSOCK"
    exit 1
fi

#Commands
#capabilities negotiation
CMD_NEGO='{ "execute": "qmp_capabilities" }'
CMD_MOUNT_RD4='
{"execute":"device_add",
  "arguments":{
    "id":"pm3", 
    "driver":"usb-host", 
    "bus":"usb-bus.0", 
    "vendorid":"0x9ac4",
    "productid":"0x4b8f"
  }
}'

echo "Executing $0 ..."
echo -e "${CMD_NEGO}\n${CMD_MOUNT_RD4}" | socat - $QMPPORT

echo "$0 finished"

