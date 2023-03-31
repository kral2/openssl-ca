# OpenSSL-CA

## A quick take on Root Certificate Authority, using OpenSSL only

I was not aware that OpenSSL had all the required tooling to act as a CA, without any external tool. It will generate keys, certificates, process CSRs, and also keep track of issued certificates using a simple file database, etc. All of this is included in the brave OpenSSL. I agree that calling it a PKI is a bit of a stretch, as you still have to figure out how to process the certificate signing requests (for your mental health, in an automated way I hope), maintain a CRL and/or OCSP service, etc.

But to configure a Root CA that will probably only issue certificates for a handful of Intermediate CA, and then stay offline anyway, OpenSSL may be good enough.

Also, deploying a Root CA with OpenSSL from scratch, bare-bone, definitely helps in gaining fundamental knowledge about how a PKI should work and what is the responsibility of each component.

*Acknowledgment:*

- This project is based on the [OpenSSL Certificate Authority](https://jamielinux.com/docs/openssl-certificate-authority/index.html) documentation from Jamie Nguyen.
- Two other interesting projects I would like to mention here: [minica](https://github.com/jsha/minica) and [mkcert](https://github.com/FiloSottile/mkcert). They can both help to handle TLS Certificates for local development, even if the scenario for this project is slightly different.

## Principles

I want to build a simple Root CA based on OpenSSL with minimum external dependencies, for development purposes. It should run easily on my laptop and I should be able to start from scratch quickly, with minimum overhead and manual tasks.

I should be able to start a brand new Root CA for each development session, without repeating a list of arcane OpenSSL commands or copy/pasting a different answer from StackOverflow each time :-). Data is persisted on disk, so I can build upon the same context over time, or I can start back from a known clean initial state. À la carte.

The solution is not meant to deploy and use a Root CA in production for VeryBigCorp .Inc. But it should be as close as possible to a realistic enterprise architecture, so I can build realistic labs and demos.

## The solution

There are two helper scripts:

- `00_init_openssl_ca_root.sh`
- `00_init_openssl_ca_intermediate.sh`

They will respectively generate the required files to have a Root CA (valid for 1 year) and one Intermediate CA (valid for 90 days). Creating an Intermediate CA with this script is optional.

Once you have generated the files for your Root CA, you can copy the `ca` folder to a secure place and operate your PKI like a semi-pro. The machine from where these files were generated is not relevant.

For a real PKI-pro experience, I would recommend adding [Vault](https://vaultproject.io) as an Intermediate CA to the mix and using it to issue any server or client certificates :-)

## Requirements

- BASH
- OpenSSL
- Coreutils: sed, realpath

## Usage

To deploy a new Root CA, with all its files in the `ca` folder under the current directory:

```shell
./00_init_openssl_ca_root.sh
```

Answer the few prompts, and at the end of the process you should have an output similar to this:

```shell
Running 00_init_openssl_ca_root.sh - version 0.1.0

[...]

*** Summary
Your Root CA is initialized under folder 'ca'.

ca
├── certs
│   └── ca.cert.pem
├── crl
├── index.txt
├── newcerts
├── openssl.cnf
├── private
│   └── ca.key.pem
└── serial
```

Similarly, if you want to add an Intermediate CA signed by your new Root CA, execute this script and follow the prompts:

```shell
./00_init_openssl_ca_intermediate.sh
```

```shell
Running 00_init_openssl_ca_intermediate.sh - version 0.1.0

[...]

*** Summary
Your Intermediate CA is initialized under folder 'ca/intermediate'.

ca/intermediate
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
└── serial
```
