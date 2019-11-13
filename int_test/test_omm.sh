#!/usr/bin/env bash

. ${T}/common_test.sh || exit $?

setup()
{
  build_int_common

  # copy the latest version of caom2tools code that's required for a python
  # install - use the minimal amount of the repo contents
  echo "Copy the source code ..."
  copy_pip_install ${OMM_ROOT} omm2caom2 omm2caom2

  echo "Build omm container ..."
  output=$(docker build -f ./Dockerfile.omm -t omm_run_int ./ 2>&1 || exit $?)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "${output}"
    echo "docker build failed for omm"
    exit 1
  fi

  echo "Get the latest version of the files under test where it matters ..."
  cd ${RUN_ROOT}/store_ingest_modify || exit $?
  cadc-data get --cert $HOME/.ssl/cadcproxy.pem OMM C180616_0135_SCI.fits.gz || exit $?
  cd ${RUN_ROOT} || exit $?
  echo "Copy cert for store_ingest_modify."
  cp $HOME/.ssl/cadcproxy.pem ${RUN_ROOT}/store_ingest_modify || exit $?
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
      exit 1
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
  if [[ -e ${run_dir}/metrics ]]
  then
    echo "clean up metrics directory"
    cleanup_files "${run_dir}/metrics/*.yml"
    sudo rmdir ${run_dir}/metrics || exit $?
  fi

  echo "docker run --rm -v ${run_dir}:${CONT_ROOT} omm_run_int omm_run 2>&1"
  output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} omm_run_int omm_run 2>&1)"
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    if [[ ${ii} != "failures" ]]
    then
      echo "${output}"
      echo "omm_run failed with result status ${result} for ${1}"
      exit 1
    fi
  fi
  if [[ ${output} != *" correctly"* ]]
  then
    if [[ ${ii} != "failures" ]]
    then
      echo "${output}"
      echo "omm_run failed for ${1}"
      exit 1
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
    if [[ ${result} -ne 255 ]]
    then
      echo "omm_run failed for ${ii}"
      exit 1
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

msg=$(echo -n "$(basename $0) Success at: " $(date))
echo $msg
echo $msg >> $I/execution_log.txt
