#!/bin/bash

. ${T}/common_test.sh || exit ?

ROOT_DIR="${D}"
COLLECTIONS=( gem cgps omm vlass drao26m draost draosfm draogmims askap )

# provide a collection name as a parameter to 'run just one' set of
# unit tests
if [[ $# -eq 1 ]]
then
  test_set=( "${1}" )
else
  test_set=( ${COLLECTIONS[@]} )
fi
temp=( )
for ii in "${test_set[@]}"
do
  temp=( ${temp[@]} "${ii}2caom2" )
done
copy_set=( caom2tools ${temp[@]} ) 
build_set=( caom2utils caom2pipe ${test_set[@]} ) 

docker_cleanup

for ii in "${copy_set[@]}"
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

echo "Copy credentials into the gemini container - note that dockerignore says ignore cadcproxy.pem"
cp $HOME/.ssl/cadcproxy.pem ./gem2caom2_unit/proxy.pem || exit $?

echo "Build the containers"
for ii in "${build_set[@]}"
do
  docker build -f ./Dockerfile.unit.${ii} -t ${ii}_unit ./ || exit $?
done

echo "Run the unit tests for each of the modules."
docker run --rm -w /usr/src/app/caom2tools/caom2utils caom2utils_unit python setup.py test || exit $?
docker run --rm -w /usr/src/app/caom2tools/caom2pipe caom2pipe_unit python setup.py test || exit $?

for ii in "${test_set[@]}"
do
  echo "docker run for ${ii}"
  output=$(docker run --rm -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test 2>&1)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "docker run failed for ${ii}"
    echo "${output}"
    exit -1
  fi
done
echo -n 'Success at: '
date
exit 0
