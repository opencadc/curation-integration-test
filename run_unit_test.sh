#!/bin/bash

# osx
ROOT_DIR="${HOME}/work/cadc/dev"

for ii in caom2tools cgps2caom2 omm2caom2 vlass2caom2 drao26m2caom2 draosfm2caom2 draost2caom2 draogmims2caom2
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
for ii in caom2utils caom2pipe cgps omm vlass drao26m draost draosfm draogmims
do
  docker build -f ./Dockerfile.unit.${ii} -t ${ii}_unit ./ || exit $?
done

# run the unit tests for each of the modules
docker run --rm -w /usr/src/app/caom2tools/caom2utils caom2utils_unit python setup.py test || exit $?
docker run --rm -w /usr/src/app/caom2tools/caom2pipe caom2pipe_unit python setup.py test || exit $?

for ii in cgps omm vlass drao26m draost draosfm draogmims
do
  docker run --rm -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test || exit $?
done
echo -n 'Success at: '
date
exit 0
