#!/bin/bash
set -e # exit on error
set -x # echo commands

PORT="${PORT:=8000}"
WHITELIST_NAME="${WHITELIST_NAME:=monad_whitelist}"

# Destroy old rules and whitelist
sudo iptables -D INPUT -p udp --dport ${PORT} -m set --match-set ${WHITELIST_NAME}  src -j ACCEPT || true
sudo iptables -D INPUT -p udp --dport ${PORT} -j DROP || true
sudo ipset destroy ${WHITELIST_NAME} || true

# Re-create the whitelist
sudo ipset create ${WHITELIST_NAME} hash:ip family inet
IP_LIST=$(monad-debug-node -c monad-bft/controlpanel.sock get-peers | grep address | cut -d\" -f 2 | cut -d: -f 1)
for IP in ${IP_LIST}; do
	echo "sudo ipset add ${WHITELIST_NAME} ${IP}"
done

sudo iptables -I INPUT -p udp --dport ${PORT} -m set --match-set ${WHITELIST_NAME} src -j ACCEPT
sudo iptables -A INPUT -p udp --dport ${PORT} -j DROP
