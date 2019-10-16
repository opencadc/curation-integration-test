#!/bin/bash

. ${T}/common_test.sh || exit $?
COLLECTIONS=( vlass cgps omm gem draost neossat )

# docker_cleanup
build_int_common
mkdir -p ${ACTUAL} || exit $?

# copy the latest version of caom2tools code that's required for a python
# install - use the minimal amount of the repo contents
copy_pip_install ${CGPS_ROOT} cgps2caom2 cgps2caom2
copy_pip_install ${GMIMS_ROOT} draogmims2caom2 draogmims2caom2

# build the containers
docker build -f ${I}/Dockerfile.cgps -t cgps_run_int ./ || exit $?

# run the container permutations that I care about

for ii in visit_cgps
do
  echo "Run ${ii} test case ..."
  run_dir=${RUN_ROOT}/${ii}

  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/logs/*.log"
  cleanup_files "${run_dir}/*.jpg"
  cp $HOME/.ssl/cadcproxy.pem ${run_dir}
  output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} cgps_run_int cgps_run 2>&1)"
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "cgps_run failed for ${ii}"
    echo "${output}"
    exit -1
  fi
  check_client_${ii}
done

. ${I}/test_vlass.sh
. ${I}/test_omm.sh
. ${I}/test_gem.sh
. ${I}/test_neossat.sh
. ${I}/test_retries.sh

echo -n 'Success at: '
date
exit 0
