#!/bin/bash

. ${T}/common_test.sh || exit ?

ROOT_DIR="${D}"
# COLLECTIONS=( gem cgps omm vlass drao26m draost draosfm draogmims askap )
COLLECTIONS=( gem omm vlass drao26m draost draosfm draogmims askap )

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
build_set=( ${test_set[@]} ) 

setup_gem()
{
  :
}

setup_omm()
{
  cp ${U}/test_files/C170324_0054_SCI.fits.gz ${U}/omm2caom2_unit/omm2caom2/tests/data || exit $?
}

setup_vlass()
{
  :
}

setup_drao26m()
{
  :
}

setup_draost()
{
  :
}

setup_draosfm()
{
  :
}

setup_draogmims()
{
  :
}

setup_askap()
{
  :
}

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

echo "Build the unit test common container."
cp ${U}/Dockerfile.unit.common caom2tools_unit || exit $?
cd ${U}/caom2tools_unit || exit $?
output=$(docker build -f ./Dockerfile.unit.common -t ${UNIT_COMMON} ./ || exit $?)
result=$?
if [[ ${result} -ne 0 ]]
then
  echo "docker build failed for ${UNIT_COMMON}"
  echo "${output}"
  exit -1
fi
cd ${U} || exit $?

echo "Build the containers ${build_set[@]}"
for ii in "${build_set[@]}"
do
  if [[ "${ii}" != "caom2utils" && ${ii} != "caom2pipe" && ${ii} != "omm" ]]
  then
    cp ${U}/Dockerfile.unit.${ii} ${U}/${ii}2caom2_unit || exit $?
    cd ${U}/${ii}2caom2_unit || exit $?
  else
    cd ${U} || exit $?
  fi
  docker build -f ./Dockerfile.unit.${ii} -t ${ii}_unit ./ || exit $?
done

echo "Run the unit tests for each of the modules."
output=$(docker run --rm -w /usr/src/app/caom2tools/caom2utils ${UNIT_COMMON} python setup.py test 2>&1)
result=$?
if [[ ${result} -ne 0 ]]
then
  echo "docker run failed for ${ii}"
  echo "${output}"
  exit -1
fi
output=$(docker run --rm -w /usr/src/app/caom2tools/caom2pipe ${UNIT_COMMON} python setup.py test 2>&1)
result=$?
if [[ ${result} -ne 0 ]]
then
  echo "docker run failed for ${ii}"
  echo "${output}"
  exit -1
fi

for ii in "${test_set[@]}"
do
  echo "setup for ${ii}"
  setup_${ii}
done

for ii in "${test_set[@]}"
do
  echo "docker run --rm -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test 2>&1"
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
