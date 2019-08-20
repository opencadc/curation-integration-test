#!/bin/bash

. ${T}/common_test.sh || exit $?

check_client_gem() {
  echo "check_client_gem"
  local _run_dir="${1}"
  failure_log="${_run_dir}/logs/failure_log.txt"
  success_log="${_run_dir}/logs/success_log.txt"
  retries_log="${_run_dir}/logs/retries.txt"
  rejected_log="${_run_dir}/logs/rejected.yml"
  file_is_not_zero ${failure_log}
  file_is_not_zero ${retries_log}
  # even an empty file has the dict keys
  file_is_zero ${rejected_log}
  file_is_zero ${success_log}
  # the named preview file does not currently exist at archive.gemini.edu
  file_does_not_have_content S20080610S0045 ${rejected_log}
  metrics="${_run_dir}/metrics"
  directory_does_not_exist ${metrics}
}

run_test_gem() {
  for ii in visit_gem
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
    echo "Get proxy cert"
    cp $HOME/.ssl/cadcproxy.pem ${run_dir} || exit $?
    docker run --rm -v ${run_dir}:/usr/src/app gem_run_int gem_run
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "gem_run_query failed for ${ii} with result ${result}"
      exit -1
    fi
  done
}

setup()
{
  build_int_common
  echo "Copy the source code ..."
  copy_pip_install ${GEM_ROOT} gem2caom2 gem2caom2
  echo "cp ${GEM_ROOT}/gem2caom2/tests/data/from_paul.txt ${RUN_ROOT}/gem2caom2"
  cp ${GEM_ROOT}/gem2caom2/tests/data/from_paul.txt ${RUN_ROOT}/gem2caom2
  
  echo "Build gem container ..."
  output=$(docker build -f ./Dockerfile.gem -t gem_run_int ./ 2>&1 || exit $?)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "docker build failed for Dockerfile.gem"
    echo "${output}"
    exit -1
  fi
}

setup
run_test_gem
check_client_gem ${RUN_ROOT}/visit_gem
check_observation_in_db GEMINI GS-2017A-Q-58-66-027
check_observation_in_db GEMINI GS-2008A-C-5-35-002
echo -n "$(basename $0) Success at: "
date
