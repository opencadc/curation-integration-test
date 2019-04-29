#!/bin/bash

. ${T}/common_test.sh || exit $?
COLLECTIONS=( vlass cgps omm gem )

docker_cleanup

# copy the latest version of caom2tools code that's required for a python
# install - use the minimal amount of the repo contents
copy_pip_install ${TOOLS_ROOT}/caom2pipe caom2tools/caom2pipe caom2pipe
copy_pip_install ${TOOLS_ROOT}/caom2utils caom2tools/caom2utils caom2utils
copy_pip_install ${TOOLS_ROOT}/caom2 caom2tools/caom2 caom2
copy_pip_install ${CGPS_ROOT} cgps2caom2 cgps2caom2
copy_pip_install ${GMIMS_ROOT} draogmims2caom2 draogmims2caom2

# build the containers
docker build -f ./Dockerfile.cgps -t cgps_run_int ./ || exit $?

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

. ./test_vlass.sh
. ./test_retries.sh
. ./test_omm.sh

echo -n 'Success at: '
date
exit 0
