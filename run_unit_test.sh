#!/bin/bash

# osx
# ROOT_DIR="${HOME}/work/cadc/dev"
ROOT_DIR="${HOME}/work/cadc"
RUN_ROOT=${ROOT_DIR}/tests/int_test

for ii in caom2tools omm2caom2 vlass2caom2
do
  sudo rsync -ai --delete ${ROOT_DIR}/${ii}/ ./${ii}_unit \
    --exclude=".git"  \
    --exclude=".eggs"  \
    --exclude=".coverage"  \
    --exclude="htmlcov"  \
    --exclude=".pytest_cache"  \
    --exclude="${ii}.egg-info"  \
    --exclude="__pycache__" || exit $?
done

# build the containers
for ii in caom2pipe omm vlass
do
  docker build -f ./Dockerfile.unit.${ii} -t ${ii}_unit ./ || exit $?
done

# run the unit tests for each of the modules
docker run --rm -w /usr/src/app/caom2tools/caom2pipe caom2pipe_unit python setup.py test
docker run --rm -w /usr/src/app/vlass2caom2 vlass_unit python setup.py test
docker run --rm -w /usr/src/app/omm2caom2 omm_unit python setup.py test
exit 0
