#!/bin/bash

mkdir -p ${U}/test_files || exit $?
cd ${U}/test_files || exit $?
for f_name in C170324_0054_SCI.fits
do
    cadc-data get --cert $HOME/.ssl/cadcproxy.pem OMM ${f_name} || exit $?
done

for f_name in VLASS1.2.ql.T24t07.J065836+563000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits
do
    cadc-data get --cert $HOME/.ssl/cadcproxy.pem VLASS ${f_name} || exit $?
done

date
exit 0
