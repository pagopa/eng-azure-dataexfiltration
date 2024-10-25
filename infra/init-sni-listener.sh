#!/bin/bash

cd /usr/bin
wget https://github.com/pagopa/eng-azure-dataexfiltration/raw/refs/heads/main/sni-listener/sni-listener-linux-amd64
chmod u+x sni-listener-linux-amd64
./sni-listener-linux-amd64 2>&1 | tee /tmp/sni-listener-linux-amd64.txt
