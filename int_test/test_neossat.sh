#!/usr/bin/env bash

. ${T}/common_test.sh || exit $?

collection="neossat"

setup()
{
  build_int_common
  # copy the latest version of caom2tools code that's required for a python
  # install - use the minimal amount of the repo contents
  echo "Copy the source code ..."
  copy_pip_install ${NEOS_ROOT} ${collection}2caom2 ${collection}2caom2

  echo "Build ${collection} container ..."
  output=$(docker build -f ./Dockerfile.${collection} -t ${collection}_run_int ./ 2>&1 || exit $?)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "${output}"
    echo "docker build failed for ${collection}"
    exit 1
  fi
}

run_int_test_case()
{
  echo "Run ${1} test case ..."
  run_dir=${RUN_ROOT}/${1}
  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/logs/*.log"
  cleanup_files "${run_dir}/*.xml"
  cleanup_files "${run_dir}/*.jpg"
  if [[ -e ${run_dir}/metrics ]]
  then
    echo "clean up metrics directory"
    cleanup_files "${run_dir}/metrics/*.yml"
    sudo rmdir ${run_dir}/metrics || exit $?
  fi

  echo "Get proxy cert"
  cp $HOME/.ssl/cadcproxy.pem ${run_dir} || exit $?

  echo "docker run --rm -v ${run_dir}:${CONT_ROOT} ${collection}_run_int ${collection}_run 2>&1"
  output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} ${collection}_run_int ${collection}_run 2>&1)"
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    if [[ ${ii} != "failures" ]]
    then
      echo "${output}"
      echo "${collection}_run failed with result status ${result} for ${1}"
      exit 1
    fi
  fi
  if [[ ${output} != *" correctly"* ]]
  then
    if [[ ${ii} != "failures" ]]
    then
      echo "${output}"
      echo "${collection}_run failed for ${1}"
      exit 1
    fi
  fi
  echo "${output}"
  check_${1} "${output}"
}

run_tests() {
  # test those permutations that don't support the command-line parameter
  for ii in ingest_modify_${collection}
  do
    run_int_test_case "${ii}"
  done
}

setup
run_tests

echo -n "$(basename $0) Success at: "
date
