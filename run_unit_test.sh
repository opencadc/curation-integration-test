#!/bin/bash

ROOT_DIR="${HOME}/work/cadc/dev"

# clean up, before I run out of space
# remove stopped images
output=$(docker ps -a -f status=exited -q)
if [[ ! -z "${output}" ]]
then
  for ii in ${output}
  do
    docker rm ${ii} || exit $?
  done
fi

# delete unused images
output=$(docker images -qf "dangling=true")
if [[ ! -z "${output}" ]]
then
  for ii in ${output}
  do
    docker rmi ${ii} || exit $?
  done
fi


# for ii in caom2tools gem2caom2 cgps2caom2 omm2caom2 vlass2caom2 drao26m2caom2 draosfm2caom2 draost2caom2 draogmims2caom2
for ii in caom2tools gem2caom2 
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
#for ii in caom2utils caom2pipe gem cgps omm vlass drao26m draost draosfm draogmims
for ii in caom2utils caom2pipe gem 
do
  docker build -f ./Dockerfile.unit.${ii} -t ${ii}_unit ./ || exit $?
done

# run the unit tests for each of the modules
docker run --rm -w /usr/src/app/caom2tools/caom2utils caom2utils_unit python setup.py test || exit $?
docker run --rm -w /usr/src/app/caom2tools/caom2pipe caom2pipe_unit python setup.py test || exit $?

# for ii in gem cgps omm vlass drao26m draost draosfm draogmims
for ii in gem 
do
  docker run --rm -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test || exit $?
done
echo -n 'Success at: '
date
exit 0
