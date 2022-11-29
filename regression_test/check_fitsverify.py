"""
1. Find the name of the file on disk to test with.
2. Run fitsverify - mostly to make sure the Dockerfile is built properly.
"""

import sys
from caom2pipe.astro_composable import check_fitsverify
from does_collection_clean_up import question
from glob import glob

collection = sys.argv[1].upper()

cleans_up = question(collection.lower())
data_location = '/usr/src/app'
if cleans_up:
    data_location = '/data'

f_names = glob(f'{data_location}/*.fits')
found = False
for fqn in f_names:
    print('::: run fitsverify')
    found = True
    if check_fitsverify(fqn):
        print(f'fitsverify succeeded for {fqn}')
    else:
        print(f'fitsverify failed for {fqn}')
        sys.exit(-1)

if not found:
    print(f'No file with which to check fitsverify')
    sys.exit(-1)

sys.exit(0)
