#!/bin/bash

. ${T}/common_test.sh || exit $?

check_client_retries() {
  echo "check_client_retries"
  local _run_dir="${1}"
  failure_log="${_run_dir}/logs/failure_log.txt"
  success_log="${_run_dir}/logs/success_log.txt"
  retries_log="${_run_dir}/logs/retries.txt"
  file_is_zero ${failure_log}
  file_is_zero ${retries_log}
  file_is_zero ${success_log}
  rfailure_log="${_run_dir}/logs_0/failure_log.txt"
  rsuccess_log="${_run_dir}/logs_0/success_log.txt"
  rretries_log="${_run_dir}/logs_0/retries.txt"
  file_is_zero ${rfailure_log}
  file_is_zero ${rretries_log}
  file_is_not_zero ${rsuccess_log}
  file1_log="${_run_dir}/logs/B120402_domeflat_J_CALRED.log"
  file2_log="${_run_dir}/logs/C180108_0002_SCI.log"
  file1_retry_log="${_run_dir}/logs_0/B120402_domeflat_J_CALRED.log"
  file2_retry_log="${_run_dir}/logs_0/C180108_0002_SCI.log"
  file_is_zero ${file1_log}
  file_is_zero ${file2_log}
  file_exists ${file2_retry_log}
  file_is_zero ${file1_retry_log}
  # make sure there are not more retries than expected
  unexpected_retry_log_dir1="${_run_dir}/logs_1"
  unexpected_retry_log_dir2="${_run_dir}/logs_0_0"
  file_exists ${unexpected_retry_log_dir1}
  file_exists ${unexpected_retry_log_dir2}
  metrics="${_run_dir}/metrics"
  directory_does_not_exist ${metrics}
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
    cleanup_files "${run_dir}/metrics/*.yml"
    if [[ -e "${run_dir}/logs_0/" ]]
    then
      sudo rmdir "${run_dir}/logs_0/" || exit $?
    fi
    if [[ -e "${run_dir}/metrics/" ]]
    then
      sudo rmdir "${run_dir}/metrics/" || exit $?
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
    echo "${output}"
    check_client_${ii} ${run_dir}
  done
}

setup()
{
  build_int_common

  # copy the latest version of caom2tools code that's required for a python
  # install - use the minimal amount of the repo contents
  echo "Copy the source code ..."
  copy_pip_install ${OMM_ROOT} omm2caom2 omm2caom2
  
  echo "Build retries container ..."
  docker_build=$(docker build -f ./Dockerfile.omm -t omm_run_int ./ 2>&1 || exit $?)
}

# the retries test has one file that succeeds, and one file that fails, because
# that way the retry test will show that the file that succeeds is not 
# re-done, only the one that fails
#
# for the failure case, use a file that has an invalid observation ID.

setup
run_test_retries
echo -n "$(basename $0) Success at: "
date
