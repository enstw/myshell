#!/bin/zsh

set -e
BREW_M1_PATH=/opt/homebrew/bin
BREW_X86_PATH=/usr/local/bin

if [ -d "$BREW_M1_PATH" ]; then
  BREW_PATH=$BREW_M1_PATH
else
  BREW_PATH=$BREW_X86_PATH
fi

PATH=$BREW_PATH:/usr/sbin:$PATH

STATUS=""

check_status () {
  STATUS=$(limactl list default --json | jq .status)
  local t="STATUS=$STATUS"
  # remove double quote
  eval $t
}


while true ; do
  check_status
  if [ "Broken" = $STATUS ]; then
    # Force off
    echo "Instance broken. force off"
    limactl stop -f default
  fi
  if [ "Stopped" = $STATUS ]; then
    # restart it
    echo "Instance stopped. Starting instance"
    limactl start default
  fi
  sleep 2
done
