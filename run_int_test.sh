#!/bin/bash

. ./common_int_test.sh || exit $?

# copy the latest version of caom2tools code that's required for a python
# install - use the minimal amount of the repo contents
copy_pip_install ${TOOLS_ROOT}/caom2pipe caom2tools/caom2pipe caom2pipe
copy_pip_install ${TOOLS_ROOT}/caom2utils caom2tools/caom2utils caom2utils
copy_pip_install ${VLASS_ROOT} vlass2caom2 vlass2caom2
copy_pip_install ${CGPS_ROOT} cgps2caom2 cgps2caom2
copy_pip_install ${OMM_ROOT} omm2caom2 omm2caom2

mkdir -p vlass2caom2/data || exit $?
cp ${VLASS_ROOT}/data/ArchiveQuery-2018-08-15.csv vlass2caom2/data || exit $?
cp ${VLASS_ROOT}/data/rejected_file_names-2018-09-05.csv vlass2caom2/data || exit $?

# build the containers
docker build -f ./Dockerfile.cgps -t cgps_run_int ./ || exit $?
docker build -f ./Dockerfile.omm -t omm_run_int ./ || exit $?
docker build -f ./Dockerfile.vlass -t vlass_run_int ./ || exit $?

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

# test the permutations that support a client-based implementation for VLASS
for ii in ingest
do
  echo "Run ${ii} test case ..."
  run_dir=${RUN_ROOT}/${ii}

  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/*.jpg"
  cp $HOME/.ssl/cadcproxy.pem ${run_dir}
  docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run_single VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits /usr/src/app/cadcproxy.pem
  docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run_single VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits /usr/src/app/cadcproxy.pem
  docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run_single VLASS1.1.ql.T10t12.J075402-033000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits /usr/src/app/cadcproxy.pem
  docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run_single VLASS1.1.ql.T10t12.J075402-033000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits /usr/src/app/cadcproxy.pem
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "vlass_run_single failed for ${ii}"
    exit -1
  fi
  check_client_${ii}
done

for ii in visit
do
  echo "Run ${ii} test case ..."
  run_dir=${RUN_ROOT}/${ii}

  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/logs/*.log"
  cleanup_files "${run_dir}/*.jpg"
  cp $HOME/.ssl/cadcproxy.pem ${run_dir}
  output="$(docker run --rm -v ${run_dir}:${CONT_ROOT} vlass_run_int vlass_run 2>&1)"
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "vlass_run failed for ${ii}"
    echo "${output}"
    exit -1
  fi
  check_client_${ii}
done

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
    echo "omm_run failed for ${ii}"
    echo "${output}"
    exit -1
  fi
  if [[ ${output} != *" correctly"* ]]
  then
    if [[ ${ii} != "failures" ]]
    then
      echo "${output}"
      echo "omm_run failed for ${ii}"
      exit -1
    fi
  fi
  echo "${output}"
  check_${ii} "${output}"
}

# test those permutations that don't support the command-line parameter
for ii in failures scrape scrape_modify store_ingest_modify ingest_modify_local ingest_modify
do
  omm_run_int_test_case "${ii}"
done

. ./test_retries.sh
run_test_retries

echo -n 'Success at: '
date
exit 0
