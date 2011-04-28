#!/bin/bash

if [[ $1 = /dev/??? && -b $1]]; then
	if [[ $(type -P "openssl") && $(type -P "pv") ]]; then
		openssl enc -aes256 -k "foo" < /dev/urandom | pv -trb > $1
	else echo -e "OpenSSL and PV need to be installed... \n"
	fi
else echo -e "Please supply a valid hard drive to wipe: EX: /dev/sda \n"
fi
