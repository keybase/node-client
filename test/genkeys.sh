#!/bin/bash

D=./keypool

for ((i = 0; i < 20; i++))
do
   (cat - | gpg --keyring $D/pubring.gpg \
                --secret-keyring $D/secring.gpg \
                --no-default-keyring \
		--gen-key \
		--batch) <<EOF
Key-Type: RSA
Key-Length: 1024
Subkey-Type: RSA
Subkey-Length: 1024
Name-Real: Test
Name-Comment: $i
Name-Email: test+$i@test.keybase.io
%transient-key
%no-protection
%commit
EOF

done
