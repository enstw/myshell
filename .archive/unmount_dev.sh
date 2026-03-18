#!/bin/bash

set -e

INS=default
PATH=opt/homwbrew/bin:$PATH
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
CMD_MOUNT_RD4='{"execute":"device_del", "arguments":{"id":"pm3"}}'

echo "Mounting devices..."
echo -e "${CMD_NEGO}\n${CMD_MOUNT_RD4}" | socat - $QMPPORT

echo "Mount finished"

