#!/bin/bash

# Last update : March, 2023
# Author: kral2
# Description: Init a PKI Intermediate CA using OpenSSL
# Based on https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html

script_name=$(basename "$0")
version="0.1.0"

echo "Running $script_name - version $version"
echo ""

CA_BASE_DIR="ca"
CA_INT_BASE_DIR="${CA_BASE_DIR}/intermediate"

## Check if a Root CA exist in the current directory before proceeding

RESET_INTERMEDIATE_CA="Y"

if [ -d $CA_INT_BASE_DIR ]; then
  echo "WARNING! A Intermediate CA is already present in this subdirectory."
  echo "If you proceed, the existing Intermediate CA folder and all its content will be deleted."
  read -rp "Do you want to reset your Root CA with default configuration? (Y/n): " RESET_INTERMEDIATE_CA
  if # 'Y', 'y' and hit enter are the only valid inputs to proceed with cluster creation
    [ "$RESET_INTERMEDIATE_CA" == "" ] || [ "$RESET_INTERMEDIATE_CA" == "Y" ] || [ "$RESET_INTERMEDIATE_CA" == "y" ]; then
    rm -rf $CA_INT_BASE_DIR
  else # exit without action if answer is anything different that the accepted inputs
    echo "No action. Exiting."
    exit 0
  fi
fi

## Prepare the directory structure

echo ""
echo "*** PKI directory structure"

mkdir -p $CA_INT_BASE_DIR/certs $CA_INT_BASE_DIR/crl $CA_INT_BASE_DIR/csr $CA_INT_BASE_DIR/newcerts $CA_INT_BASE_DIR/private

cd $CA_INT_BASE_DIR || exit

chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

if [ ! -f openssl.cnf ]; then
    echo "No openssl config file found. Copying from template: ../../openssl_intermediate.cnftpl"
    CURRENT_DIR=$(realpath $(dirname "$0"))
    sed "s@<CURRENT_DIR>@$CURRENT_DIR@g" ../../openssl_intermediate.cnftpl > openssl.cnf
else
    echo "openssl config file found. It will be reused."
fi

## Create Intermediate key

echo ""
echo "*** Intermediate CA RSA Private Key"

read -rp "Enter a pass phrase to protect the Intermediate CA private key: " -s INT_CA_KEY_PASS_PHRASE
echo ""
echo ""
echo "*****************************************************************"
echo "Keep the resulting private key file and the associated pass phrase in a secure place."
echo "The trust on your Intermediate CA is based on the fact that you are the only one having access to"
echo "the Private Key and its associated pass phrase."
echo "*****************************************************************"
echo ""

export INT_CA_KEY_PASS_PHRASE="$INT_CA_KEY_PASS_PHRASE"

cd .. || exit
openssl genrsa -aes256 \
    -out intermediate/private/intermediate.key.pem -passout env:INT_CA_KEY_PASS_PHRASE 4096
# chmod 400 private/ca.key.pem

## Create Intermediate certificate

echo ""
echo "*** Intermediate CA Certificate Signing Request (CSR)"

openssl req -config intermediate/openssl.cnf -new -sha256 \
      -key intermediate/private/intermediate.key.pem \
      -passin env:INT_CA_KEY_PASS_PHRASE \
      -out intermediate/csr/intermediate.csr.pem

echo ""
echo "*** Root CA processing the Intermediate CA CSR"
echo "Root CA will generate a Certificate for Intermediate CA, signing it with its own private key"
echo "Please provide the pass phrase protecting the Root CA private key."
echo ""

openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
      -days 90 -notext -md sha256 \
      -in intermediate/csr/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem

# ## Verify the intermediate certificate and check agains root CA
# openssl x509 -noout -text \
#  -in intermediate/certs/intermediate.cert.pem

# openssl verify -CAfile certs/ca.cert.pem \
#   intermediate/certs/intermediate.cert.pem

## Create Certificate Chain file

echo ""
echo "*** Create Certificate Chain file"
cat intermediate/certs/intermediate.cert.pem \
      certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
# chmod 444 intermediate/certs/ca-chain.cert.pem

echo ""
echo "*** Summary"
echo "Your Intermediate CA is initialized under folder '$CA_INT_BASE_DIR'."
echo ""

echo "ca/intermediate
├── certs
│   ├── ca-chain.cert.pem
│   └── intermediate.cert.pem
├── crl
├── crlnumber
├── csr
│   └── intermediate.csr.pem
├── index.txt
├── newcerts
├── openssl.cnf
├── private
│   └── intermediate.key.pem
└── serial"
