#!/bin/bash

cd ${U} || exit $?

. ${T}/common_test.sh || exit ?

ROOT_DIR="${D}"
COLLECTIONS=( neossat gem omm vlass askap draost cgps vlite )

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
copy_set=( caom2tools caom2pipe ${temp[@]} ) 
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
  cp ${U}/test_files/VLASS1.2.ql.T24t07.J065836+563000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits ${U}/vlass2caom2_unit/vlass2caom2/tests/data || exit $?
}

setup_caom2pipe()
{
  cp ${U}/test_files/VLASS1.2.ql.T24t07.J065836+563000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits ${U}/caom2pipe_unit/caom2pipe/tests/data || exit $?
}

setup_cgps()
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

setup_neossat()
{
  :
}

setup_vlite()
{
  :
}

# docker_cleanup

for ii in "${copy_set[@]}"
do
  sudo rsync -ai --delete ${ROOT_DIR}/${ii}/ ./${ii}_unit \
    --exclude=".git"  \
    --exclude=".eggs"  \
    --exclude=".coverage"  \
    --exclude="htmlcov"  \
    --exclude=".pytest_cache"  \
    --exclude="${ii}.egg-info"  \
    --exclude="int_test"  \
    --exclude="__pycache__" || exit $?
done

echo "Copy credentials into the gemini container - note that dockerignore says ignore cadcproxy.pem"
cp $HOME/.ssl/cadcproxy.pem ./gem2caom2_unit/proxy.pem || exit $?

echo "Build the unit test common containers."
setup_caom2pipe
for container in $UNIT_COMMON $UNIT_MATPLOTLIB $UNIT_PANDAS $UNIT_CAOM2PIPE
do
  echo "build ${container}"
  output=$(docker build -f ./Dockerfile.${container} -t $container ./ || exit $?)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "${output}"
    echo "docker build failed for ${container}"
    exit -1
  fi
done

echo "Run the unit tests for caom2pipe."
output=$(docker run --rm -w /usr/src/app/caom2pipe ${UNIT_CAOM2PIPE} python setup.py test 2>&1)
result=$?
if [[ ${result} -ne 0 ]]
then
  echo "${output}"
  echo "docker run failed for caom2pipe"
  exit 1
fi

for ii in "${test_set[@]}"
do
  echo "docker build for ${ii}"
  docker build -f ./Dockerfile.unit.${ii} -t ${ii}_unit ./ || exit $?
  echo "setup for ${ii}"
  setup_${ii}
  echo "docker run --rm -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test 2>&1"
  output=$(docker run --rm -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test 2>&1)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "${output}"
    echo "docker run failed for ${ii}"
    exit 1
  fi
done
msg=$(echo -n "${test_set[@]} Success at:" $(date))
echo $msg
echo $msg >> $U/execution_log.txt
exit 0
