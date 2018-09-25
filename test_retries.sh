#!/bin/bash

. ./common_int_test.sh || exit $?

check_client_retries() {
  echo "check_client_retries"
  local _run_dir="${1}"
  failure_log="${_run_dir}/logs/failure_log.txt"
  success_log="${_run_dir}/logs/success_log.txt"
  retries_log="${_run_dir}/logs/retries.txt"
  file_is_zero ${failure_log}
  file_is_zero ${retries_log}
  file_is_not_zero ${success_log}
  rfailure_log="${_run_dir}/logs_0/failure_log.txt"
  rsuccess_log="${_run_dir}/logs_0/success_log.txt"
  rretries_log="${_run_dir}/logs_0/retries.txt"
  file_is_zero ${rfailure_log}
  file_is_zero ${rretries_log}
  file_is_not_zero ${rsuccess_log}
}

run_test_retries() {
  for ii in retries
  do
    echo "Run ${ii} test case ..."
    run_dir=${RUN_ROOT}/${ii}

    cleanup_files "${run_dir}/logs/*.txt"
    cleanup_files "${run_dir}/logs/*.log"
    cleanup_files "${run_dir}/logs_0/*.txt"
    cleanup_files "${run_dir}/logs_0/*.log"
    if [[ -e "${run_dir}/logs_0/" ]]
    then
      sudo rmdir "${run_dir}/logs_0/" || exit $?
    fi
    cp $HOME/.ssl/cadcproxy.pem ${run_dir}
    output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} omm_run_int omm_run 2>&1)"
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "omm_run failed for ${ii}"
      echo "${output}"
      exit -1
    fi
    check_client_${ii} ${run_dir}
  done
}

# copy the latest version of caom2tools code that's required for a python
# install - use the minimal amount of the repo contents
echo "Copy the source code ..."
copy_pip_install ${TOOLS_ROOT}/caom2pipe caom2tools/caom2pipe caom2pipe
copy_pip_install ${TOOLS_ROOT}/caom2utils caom2tools/caom2utils caom2utils
copy_pip_install ${OMM_ROOT} omm2caom2 omm2caom2

echo "Build the containers ..."
docker_build=$(docker build -f ./Dockerfile.omm -t omm_run_int ./ 2>&1 || exit $?)

run_test_retries
echo -n "$(basename $0) Success at: "
date
exit 0
