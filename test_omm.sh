#!/usr/bin/env bash

. ./common_int_test.sh || exit $?

setup()
{
  # copy the latest version of caom2tools code that's required for a python
  # install - use the minimal amount of the repo contents
  echo "Copy the source code ..."
  copy_pip_install ${TOOLS_ROOT}/caom2pipe caom2tools/caom2pipe caom2pipe
  copy_pip_install ${TOOLS_ROOT}/caom2utils caom2tools/caom2utils caom2utils
  copy_pip_install ${OMM_ROOT} omm2caom2 omm2caom2

  echo "Build the containers ..."
  docker_build=$(docker build -f ./Dockerfile.omm -t omm_run_int ./ 2>&1 || exit $?)

  echo "Get the latest version of the files under test where it matters ..."
  cd ${RUN_ROOT}/store_ingest_modify || exit $?
  cadc-data get --cert $HOME/.ssl/cadcproxy.pem OMM C180616_0135_SCI.fits.gz || exit $?
  cd ${RUN_ROOT} || exit $?
}

omm_run_single_test() {
  # test the permutations that support a client-based implementation for OMM
  for ii in client_ingest_modify
  do
    echo "Run ${ii} single test case ..."
    run_dir=${RUN_ROOT}/${ii}
    cleanup_files "${run_dir}/logs/*.txt"
    cleanup_files "${run_dir}/logs/*.log"
    cleanup_files "${run_dir}/*.jpg"
    cp $HOME/.ssl/cadcproxy.pem ${run_dir}
    docker run --rm -v ${run_dir}:${CONT_ROOT} omm_run_int omm_run_single C170323_domeflat_K_CALRED /usr/src/app/cadcproxy.pem
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "omm_run_single failed for ${ii}"
      exit -1
    fi
    check_${ii}
  done
  #
}

omm_run_int_test_case()
{
  echo "Run ${1} test case ..."
  run_dir=${RUN_ROOT}/${1}
  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/logs/*.log"
  cleanup_files "${run_dir}/*.xml"
  cleanup_files "${run_dir}/*.jpg"

  output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} omm_run_int omm_run 2>&1)"
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "omm_run failed for ${1}"
    echo "${output}"
    exit -1
  fi
  if [[ ${output} != *" correctly"* ]]
  then
    if [[ ${ii} != "failures" ]]
    then
      echo "${output}"
      echo "omm_run failed for ${1}"
      exit -1
    fi
  fi
  echo "${output}"
  check_${1} "${output}"
}

omm_run_todo_test_case() {
  # test the permutations that support a command-line parameter for the
  # todo file
  for ii in todo_parameter
  do
    echo "Run ${ii} test case ..."
    run_dir=${RUN_ROOT}/${ii}
    cleanup_files "${run_dir}/logs/*.txt"
    cleanup_files "${run_dir}/logs/*.log"
    # output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} omm_run_int omm_run --todo ./abc.txt 2>&1)"
    docker run --rm -v ${run_dir}:${CONT_ROOT} omm_run_int omm_run --todo ./abc.txt
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "omm_run failed for ${ii}"
      exit -1
    fi
    check_${ii}
  done
}

run_omm_tests() {
  # test those permutations that don't support the command-line parameter
  for ii in failures scrape scrape_modify store_ingest_modify ingest_modify_local ingest_modify
  do
    omm_run_int_test_case "${ii}"
  done
  omm_run_single_test
  omm_run_todo_test_case
}

setup
run_omm_tests

echo -n "$(basename $0) Success at: "
date
