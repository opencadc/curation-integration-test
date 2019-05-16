#!/bin/bash

. ${T}/common_test.sh || exit $?

APP="draost_run"
CONTAINER="draost_run_int"

check_client_pull() {
  echo "check_client_pull"
  local _run_dir="${1}"
  failure_log="${_run_dir}/logs/failure_log.txt"
  success_log="${_run_dir}/logs/success_log.txt"
  retries_log="${_run_dir}/logs/retries.txt"
  file_is_not_zero ${failure_log}
  file_exists ${retries_log}
  file_is_zero ${success_log}
  downloaded="${_run_dir}/VLASS1.2.ql.T07t14.J084202-123000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits"
  output=$(docker run --rm -v ${RUN_ROOT}:${CONT_ROOT} int_common python astropy_verify.py ${downloaded} 2>&1)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "compare_observations execution failed for ${obs_id}"
    echo "${output}"
    exit -1
  fi
}

run_test_pull() {
  for ii in pull
  do
    echo "Run ${ii} test case ..."
    run_dir=${RUN_ROOT}/${ii}

    cleanup_files "${run_dir}/logs/*.txt"
    cleanup_files "${run_dir}/logs/*.log"
    cp $HOME/.ssl/cadcproxy.pem ${run_dir}
    echo "docker run --rm -v ${run_dir}:${CONT_ROOT} ${CONTAINER} ${APP} 2>&1"
    output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} ${CONTAINER} ${APP} 2>&1)"
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "${APP} failed for ${ii}"
      echo "${output}"
      exit -1
    fi
    check_client_${ii} ${run_dir}
  done
}

setup()
{
  build_int_common

  # copy the latest version of caom2tools code that's required for a python
  # install - use the minimal amount of the repo contents
  echo "Copy the pull source code ..."
  copy_pip_install ${DRAOST_ROOT} draost2caom2 draost2caom2
  
  echo "Build pull container ..."
  docker_build=$(docker build -f ./Dockerfile.draost -t ${CONTAINER} ./ 2>&1 || exit $?)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "${APP} failed for ${ii}"
    echo "${docker_build}"
    exit -1
  fi
}

setup
run_test_pull
echo -n "$(basename $0) Success at: "
date
