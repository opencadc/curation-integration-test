#!/bin/bash

cd ${U} || exit $?

. ${T}/common_test.sh || exit ?

RUN_TEST_FILE_DIR="${U}/test_files_running"
TEST_FILES="/test_files"
ROOT_DIR="${D}"
COLLECTIONS=( neossat gem omm vlass askap draost cgps vlite cfht )

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
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_omm()
{
  rm ${RUN_TEST_FILE_DIR}/*
  cp ${U}/test_files/C170324_0054_SCI.fits.gz ${RUN_TEST_FILE_DIR} || exit $?
}

setup_vlass()
{
  rm ${RUN_TEST_FILE_DIR}/*
  cp ${U}/test_files/VLASS1.2.ql.T24t07.J065836+563000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits ${RUN_TEST_FILE_DIR} || exit $?
}

setup_caom2pipe()
{
  rm ${RUN_TEST_FILE_DIR}/*
  cp ${U}/test_files/VLASS1.2.ql.T24t07.J065836+563000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits ${RUN_TEST_FILE_DIR} || exit $?
}

setup_cgps()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_drao26m()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_draost()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_draosfm()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_draogmims()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_askap()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_neossat()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_vlite()
{
  rm ${RUN_TEST_FILE_DIR}/*
}

setup_cfht()
{
  rm ${RUN_TEST_FILE_DIR}/*
  cp ${U}/test_files/2460503p.fits ${RUN_TEST_FILE_DIR} || exit $?
  cp ${U}/test_files/979339i.fits ${RUN_TEST_FILE_DIR} || exit $?
}

docker_cleanup

for ii in "${copy_set[@]}"
do
  echo "Updating source for ${ii}"
  # the clone are named something_unit, so it's easy to add them to the .dockerignore file
  cd ${U}/${ii}_unit || exit $?
  git pull origin master || exit $?
done
echo "Done updating local source code copies."
cd ${U} || exit $?

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
# output=$(docker run --rm -w /usr/src/app/caom2pipe ${UNIT_CAOM2PIPE} python setup.py test 2>&1)
echo "docker run --rm -v ${RUN_TEST_FILE_DIR}:${TEST_FILES} -w /usr/src/app/caom2pipe ${UNIT_CAOM2PIPE} pytest"
output=$(docker run --rm -v ${RUN_TEST_FILE_DIR}:${TEST_FILES} -w /usr/src/app/caom2pipe ${UNIT_CAOM2PIPE} pytest 2>&1)
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
  echo "docker run --rm -v ${RUN_TEST_FILE_DIR}:${TEST_FILES} -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test 2>&1"
  output=$(docker run --rm -v ${RUN_TEST_FILE_DIR}:${TEST_FILES} -w /usr/src/app/${ii}2caom2 ${ii}_unit python setup.py test 2>&1)
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
