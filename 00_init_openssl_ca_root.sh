#!/bin/bash

# Last update : March, 2023
# Author: kral2
# Description: Init a PKI Root CA using OpenSSL
# Based on https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html

script_name=$(basename "$0")
version="0.1.0"

echo "Running $script_name - version $version"
echo ""

CA_BASE_DIR="ca"

## Check if a Root CA exist in the current directory before proceeding

RESET_ROOT_CA="Y"

if [ -d $CA_BASE_DIR ]; then
  echo "WARNING! A root CA is already present in this subdirectory."
  echo "If you proceed, the existing Root CA folder and all its content will be deleted."
  read -rp "Do you want to reset your Root CA with default configuration? (Y/n): " RESET_ROOT_CA
  if # 'Y', 'y' and hit enter are the only valid inputs to proceed with cluster creation
    [ "$RESET_ROOT_CA" == "" ] || [ "$RESET_ROOT_CA" == "Y" ] || [ "$RESET_ROOT_CA" == "y" ]; then
    rm -rf $CA_BASE_DIR
  else # exit without action if answer is anything different that the accepted inputs
    echo "No action. Exiting."
    exit 0
  fi
fi

## Prepare the directory structure

echo ""
echo "*** PKI directory structure"

mkdir -p $CA_BASE_DIR/certs $CA_BASE_DIR/crl ca/newcerts $CA_BASE_DIR/private

cd $CA_BASE_DIR || exit

chmod 700 private
touch index.txt
echo 1000 > serial

if [ ! -f openssl.cnf ]; then
    echo "No openssl config file found. Copying and customize from template: ../openssl_root.cnftpl"
	  CURRENT_DIR=$(realpath $(dirname "$0"))
    sed "s@<CURRENT_DIR>@$CURRENT_DIR@g" ../openssl_root.cnftpl > openssl.cnf
else
    echo "openssl config file found. It will be reused."
fi

## Create root key

echo ""
echo "*** Root CA RSA Private Key"

read -rp "Enter a pass phrase to protect the root CA private key: " -s ROOT_CA_KEY_PASS_PHRASE
echo ""
echo ""
echo "*****************************************************************"
echo "Keep the resulting private key file and the associated pass phrase in a secure place."
echo "The trust on your CA is based on the fact that you are the only one having access to"
echo "the Private Key and its associated pass phrase."
echo "You will need to provide the pass phrase for any cryptograhic operation on the Root CA."
echo "*****************************************************************"
echo ""

export ROOT_CA_KEY_PASS_PHRASE="$ROOT_CA_KEY_PASS_PHRASE"
openssl genrsa -aes256 -out private/ca.key.pem -passout env:ROOT_CA_KEY_PASS_PHRASE 4096
# chmod 400 private/ca.key.pem

## Create root certificate

echo ""
echo "*** Root CA Certificate (Self-Signed)"

openssl req -config openssl.cnf \
      -key private/ca.key.pem \
      -new -x509 -days 365 -sha256 -extensions v3_ca \
      -passin env:ROOT_CA_KEY_PASS_PHRASE \
      -out certs/ca.cert.pem
# chmod 444 certs/ca.cert.pem

## Verify the root certificate
# openssl x509 -noout -text -in certs/ca.cert.pem

echo ""
echo "*** Summary"
echo "Your Root CA is initialized under folder '$CA_BASE_DIR'."
echo ""
echo "ca
├── certs
│   └── ca.cert.pem
├── crl
├── index.txt
├── newcerts
├── openssl.cnf
├── private
│   └── ca.key.pem
└── serial"
