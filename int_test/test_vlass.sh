#!/bin/bash

. ${T}/common_test.sh || exit $?

setup(){
  build_int_common

  echo "Copy vlass source code ..."
  copy_pip_install ${VLASS_ROOT} vlass2caom2 vlass2caom2
  mkdir -p vlass2caom2/data || exit $?
  cp ${VLASS_ROOT}/data/* vlass2caom2/data || exit $?

  echo "Build vlass container."
  docker_build=$(docker build -f ./Dockerfile.vlass -t vlass_run_int ./ 2>&1 || exit $?)
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "${docker_build}"
    echo "docker build failed for vlass"
    exit 1
  fi
}

test_vlass_visit() {
  for ii in visit
  do
    echo "Run ${ii} test case ..."
    run_dir=${RUN_ROOT}/${ii}

    cleanup_files "${run_dir}/logs/*.txt"
    cleanup_files "${run_dir}/logs/*.log"
    cleanup_files "${run_dir}/*.jpg"
    cp $HOME/.ssl/cadcproxy.pem ${run_dir} || exit $?
    echo "docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run 2>&1"
    output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run 2>&1)"
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "${output}"
      echo "vlass_run failed for ${ii}"
      exit 1
    fi
    check_client_${ii}
  done
}

test_vlass_client() {
  # test the permutations that support a client-based implementation for VLASS
  for ii in ingest
  do
    echo "Run ${ii} test case ..."
    run_dir=${RUN_ROOT}/${ii}

    cleanup_files "${run_dir}/logs/*.txt"
    cleanup_files "${run_dir}/*.jpg"
    cp $HOME/.ssl/cadcproxy.pem ${run_dir} || exit $?
    echo "docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run_single https://archive-new.nrao.edu/vlass/quicklook/VLASS1.1/T01t01/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits /usr/src/app/cadcproxy.pem"
    for url in https://archive-new.nrao.edu/vlass/quicklook/VLASS1.1/T01t01/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits https://archive-new.nrao.edu/vlass/quicklook/VLASS1.1/T01t01/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1/VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits https://archive-new.nrao.edu/vlass/quicklook/VLASS1.1/T10t12/VLASS1.1.ql.T10t12.J075402-033000.10.2048.v1/VLASS1.1.ql.T10t12.J075402-033000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits https://archive-new.nrao.edu/vlass/quicklook/VLASS1.1/T10t12/VLASS1.1.ql.T10t12.J075402-033000.10.2048.v1/VLASS1.1.ql.T10t12.J075402-033000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits
    do
        docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run_single ${url} /usr/src/app/cadcproxy.pem
        result=$?
        if [[ ${result} -ne 0 ]]
        then
          echo "vlass_run_single failed for ${ii} ${url}"
          exit 1
        fi
    done
    check_client_${ii}
  done
}

test_vlass_state() {
  echo "test_vlass_state"
  # tests the state.yml controlled execution
  # make the deadline 1 day in the future
  # so real files aren't affected
  run_dir=${RUN_ROOT}/vlass_state

  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/logs/*.log"
  cleanup_files "${run_dir}/metrics/*.yml"
  cp $HOME/.ssl/cadcproxy.pem ${run_dir} || exit $?
  tomorrow=$(date -v +1d "+%d-%b-%Y %H:%M")
  echo "bookmarks:
  vlass_timestamp:
    last_record: $tomorrow
" > ${run_dir}/state.yml
  docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run_state
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "vlass_run_state failed"
    exit 1
  fi

  # checks - no logs are created if nothing is done
  progress_log="${run_dir}/logs/progress.txt"
  failure_log="${run_dir}/logs/failure_log.txt"
  success_log="${run_dir}/logs/success_log.txt"
  file_exists ${failure_log}
  file_exists ${success_log}
  file_exists ${progress_log}
}

run_vlass_tests() {
  test_vlass_client
  test_vlass_visit
  test_vlass_state
}

setup
run_vlass_tests

echo -n "$(basename $0) Success at: "
date
