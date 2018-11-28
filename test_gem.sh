#!/bin/bash

. ./common_int_test.sh || exit $?

check_client_gem() {
  echo "check_client_gem"
  local _run_dir="${1}"
  failure_log="${_run_dir}/logs/failure_log.txt"
  success_log="${_run_dir}/logs/success_log.txt"
  retries_log="${_run_dir}/logs/retries.txt"
  file_is_not_zero ${failure_log}
  file_is_not_zero ${retries_log}
  file_is_zero ${success_log}
}

run_test_gem() {
  for ii in gem
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
    # output="$(docker run --rm gem_run_int gem_run_query 2018-10-19 2018-10-20 abc 2>&1)"
    proxy_content=$(cat ${HOME}/.ssl/cadcproxy.pem)
    docker run --rm gem_run_int gem_run_query 2018-10-19T02:00:00 2018-10-19T14:00:00 "${proxy_content}"
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "gem_run_query failed for ${ii}"
      # echo "${output}"
      exit -1
    fi
    # echo "${output}"
  done
}

setup()
{
  # copy the latest version of caom2tools code that's required for a python
  # install - use the minimal amount of the repo contents
  echo "Copy the source code ..."
  copy_pip_install ${TOOLS_ROOT}/caom2pipe caom2tools/caom2pipe caom2pipe
  copy_pip_install ${TOOLS_ROOT}/caom2utils caom2tools/caom2utils caom2utils
  copy_pip_install ${GEM_ROOT} gem2caom2 gem2caom2
  cp $HOME/.ssl/cadcproxy.pem ${RUN_ROOT}/gem2caom2/proxy.pem
  cp ${GEM_ROOT}/config.yml ${RUN_ROOT}/gem2caom2
  
  echo "Build the containers ..."
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
#check_client_gem ${RUN_ROOT}/retries
echo -n "$(basename $0) Success at: "
date
exit 0
