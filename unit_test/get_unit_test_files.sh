#!/bin/bash

cd ${U}/test_files || exit $?
for f_name in C170324_0054_SCI.fits
do
    cadc-data get --cert $HOME/.ssl/cadcproxy.pem OMM ${f_name} || exit $?
done

date
exit 0
