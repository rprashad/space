#!/bin/bash

server=$BASH_ARGV

if [[ -z $server  ]]; then
  server="server"
fi

echo "Server: $server"

mkdir $server
cd $server

# gen private key
 openssl genrsa -des3 -out ${server}.key 1024

# gen csr
 openssl req -new -key ${server}.key -out ${server}.csr

# remove passphrase from key
 cp ${server}.key ${server}.key.org
 openssl rsa -in ${server}.key.org -out ${server}.key 

# gen self-signing cert
 openssl x509 -req -days 365 -in ${server}.csr -signkey ${server}.key -out ${server}.crt

# validate

openssl x509 -noout -modulus -in ${server}.crt | openssl md5
openssl rsa -noout -modulus -in ${server}.key | openssl md5
openssl req -noout -modulus -in ${server}.csr | openssl md5
