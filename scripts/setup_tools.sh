#!/bin/bash

cd /tmp

foundryup
cp /root/.foundry/bin/cast /usr/local/bin/cast

export SHELL=bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
source /root/.bashrc

cd /opt
