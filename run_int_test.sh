#!/bin/bash

ROOT_DIR="${HOME}/work/cadc"
RUN_ROOT=${ROOT_DIR}/tests/int_test
TOOLS_ROOT=${ROOT_DIR}/caom2tools
OMM_ROOT=${ROOT_DIR}/omm2caom2
VLASS_ROOT=${ROOT_DIR}/vlass2caom2

# stop if a file has any content
file_is_zero() {
  if [[ -e  ${1} ]]
  then
    if [[ ! -s ${1} ]]
    then
      echo "${1} not generated."
      exit -1
    fi
  else
    echo "${1} should exist."
    exit -1
  fi
}

# stop if a file doesn't have content
file_is_not_zero() {
  if [[ -e  ${1} ]]
  then
    if [[ -s ${1} ]]
    then
      echo "${1} generated."
      exit -1
    fi
  else
    echo "${1} should exist."
    exit -1
  fi
}

# stop if a file exists
file_exists() {
  if [[ -e  ${1} ]]
  then
    echo "${1} should not exist."
    exit -1
  fi
}

# stop if a file has specific content
file_has_content() {
  if grep "${1}" "${2}"
  then
    echo "${1} not expected in ${2}."
    exit -1
  fi
}

# stop if a file does not have specific content
file_does_not_have_content() {
  if ! grep "${1}" "${2}"
  then
    echo "${1} expected in ${2}."
    exit -1
  fi
}

check_complete() {
  echo "check_${1}"
  failure_log="${RUN_ROOT}/${1}/logs/failure_log.txt"
  success_log="${RUN_ROOT}/${1}/logs/success_log.txt"
  xml="${RUN_ROOT}/${1}/${2}.fits.xml"
  prev="${RUN_ROOT}/${1}/${2}_prev.jpg"
  thumb="${RUN_ROOT}/${1}/${2}_prev_256.jpg"
  file_is_not_zero ${failure_log}
  file_is_zero ${success_log}
  file_is_zero ${xml}
  file_is_zero ${prev}
  file_is_zero ${thumb}
  # footprint generation is invoked
  file_does_not_have_content "caom2:bounds" ${xml}
}

check_failures() {
  echo 'check_failures'
  failure_log="${RUN_ROOT}/failures/logs/failure_log.txt"
  file_is_zero ${failure_log}
}

check_scrape() {
  echo 'check_scrape'
  echo "${1}"
  failure_log="${RUN_ROOT}/scrape/logs/failure_log.txt"
  success_log="${RUN_ROOT}/scrape/logs/success_log.txt"
  xml="${RUN_ROOT}/scrape/C120902_sh2-132_J_old_SCIRED.fits.xml"
  file_is_not_zero ${failure_log}
  file_is_zero ${success_log}
  file_is_zero ${xml}
  # caom2repo service is not invoked
  file_has_content "caom2:metaChecksum" ${xml}
  # footprint generation is not invoked
  file_has_content "caom2:bounds" ${xml}
}

check_scrape_modify() {
  check_complete scrape_modify C170324_0054_SCI
}

check_store_ingest_modify() {
  check_complete store_ingest_modify C180616_0135_SCI
  # caom2repo service is working
  xml="${RUN_ROOT}/store_ingest_modify/C180616_0135_SCI.fits.xml"
  log="${RUN_ROOT}/store_ingest_modify/logs/C180616_0135_SCI.log"
  file_does_not_have_content "caom2:metaChecksum" ${xml}
  # the content checksum is being executed
  file_does_not_have_content "TaskType.CHECKSUM" ${log}
}

check_ingest_modify_local() {
  check_complete ingest_modify_local C080121_0339_SCI
  # caom2repo service is working
  xml="${RUN_ROOT}/ingest_modify_local/C080121_0339_SCI.fits.xml"
  #
  # this file will not have footprintfinder results, because there
  # is no WCS in it - but check to make sure that is what's
  # actually happening, and that the log message is doing the output
  #
  log="${RUN_ROOT}/ingest_modify_local/logs/C080121_0339_SCI.log"
  txt="${RUN_ROOT}/ingest_modify_local/logs/C080121_0339_SCI_footprint.txt"
  file_does_not_have_content "caom2:metaChecksum" ${xml}
  # file_does_not_have_content "footprint generation" ${log}
  file_is_zero ${txt}
}

check_ingest_modify() {
  echo 'check_ingest_modify'
  failure_log="${RUN_ROOT}/ingest_modify/logs/failure_log.txt"
  success_log="${RUN_ROOT}/ingest_modify/logs/success_log.txt"
  fname="C170323_domeflat_K_CALRED"
  xml="${RUN_ROOT}/ingest_modify/${fname}.fits.xml"
  prev="${RUN_ROOT}/ingest_modify/${fname}_prev.jpg"
  thumb="${RUN_ROOT}/ingest_modify/${fname}_prev_256.jpg"
  file_is_not_zero ${failure_log}
  file_is_zero ${success_log}
  file_exists ${xml}
  file_exists ${prev}
  file_exists ${thumb}
}

check_client_augment() {
  echo 'check_client_augment'
  fname=" VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits"
  xml="${RUN_ROOT}/augment/VLASS1.1.T01t01.J000228-363000.xml"
  file_exists ${xml}
}

check_client_ingest_modify() {
  echo 'check_client_ingest_modify'
  failure_log="${RUN_ROOT}/ingest_modify/logs/failure_log.txt"
  success_log="${RUN_ROOT}/ingest_modify/logs/success_log.txt"
  fname="C170323_domeflat_K_CALRED"
  xml="${RUN_ROOT}/ingest_modify/${fname}.fits.xml"
  prev="${RUN_ROOT}/ingest_modify/${fname}_prev.jpg"
  thumb="${RUN_ROOT}/ingest_modify/${fname}_prev_256.jpg"
  file_exists ${failure_log}
  file_exists ${success_log}
  file_exists ${xml}
  file_exists ${prev}
  file_exists ${thumb}
}

check_todo_parameter() {
  echo 'check_todo_parameter'
  failure_log="${RUN_ROOT}/todo_parameter/logs/abc_failure.log"
  success_log="${RUN_ROOT}/todo_parameter/logs/abc_success.log"
  file_is_zero ${failure_log}
  file_is_not_zero ${success_log}
}

check_client_visit() {
  echo 'check_client_visit'
  failure_log="${RUN_ROOT}/visit/logs/failure_log.txt"
  success_log="${RUN_ROOT}/visit/logs/success_log.txt"
  file_is_not_zero ${failure_log}
  file_is_zero ${success_log}
}

cleanup_files() {
#  echo "Cleaning up ${1}"
  for f in ${1}
  do
#    echo "found ${f}"
    if [[ -f "${f}" ]]
    then
#      echo "removing ${f}"
      sudo rm "${f}" || exit $?
    fi
  done
}

# copy the latest version of python code that's required for a pip install
# on a container
copy_pip_install() {
  mkdir -p ${2} || exit $?
  rm ${2}/*.py
  rm ${2}/*.cfg
  rm ${2}/*.md
  rm ${2}/${3}/*.py
  cp ${1}/setup.py ${2} || exit $?
  cp ${1}/setup.cfg ${2} || exit $?
  if [[ -e ${1}/README.rst ]]
  then
    cp ${1}/README.rst ${2} || exit $?
  fi
  if [[ -e ${1}/README.md ]]
  then
    cp ${1}/README.md ${2} || exit $?
  fi
  mkdir -p ${2}/${3} || exit $?
  cp ${1}/${3}/*.py ${2}/${3} || exit $?
}

# copy the latest version of caom2tools code that's required for a python
# install - use the minimal amount of the repo contents
copy_pip_install ${TOOLS_ROOT}/caom2pipe caom2tools/caom2pipe caom2pipe
copy_pip_install ${TOOLS_ROOT}/caom2utils caom2tools/caom2utils caom2utils
copy_pip_install ${VLASS_ROOT} vlass2caom2 vlass2caom2

mkdir -p vlass2caom2/data || exit $?
cp ${VLASS_ROOT}/data/ArchiveQuery-2018-08-15.csv vlass2caom2/data || exit $?

# copy the latest version of omm2caom2 code that's required for a python install
mkdir -p omm2caom2 || exit $?
rm omm2caom2/*.py
rm omm2caom2/*.cfg
rm omm2caom2/*.md
rm omm2caom2/omm2caom2/*.py
cp ${OMM_ROOT}/setup.py omm2caom2 || exit $?
cp ${OMM_ROOT}/setup.cfg omm2caom2 || exit $?
cp ${OMM_ROOT}/README.md omm2caom2 || exit $?
mkdir -p ${OMM_ROOT}/omm2caom2 || exit $?
cp ${OMM_ROOT}/omm2caom2/*.py omm2caom2/omm2caom2 || exit $?

# build the containers
docker build -f ./Dockerfile.omm -t omm_run_int ./ || exit $?
docker build -f ./Dockerfile.vlass -t vlass_run_int ./ || exit $?

# run the container permutations that I care about

for ii in visit
do
  echo "Run ${ii} test case ..."
  run_dir=${RUN_ROOT}/${ii}

  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/*.jpg"
  cp $HOME/.ssl/cadcproxy.pem ${run_dir}
  output="$(docker run --rm -v ${run_dir}:/usr/src/app vlass_run_int vlass_run 2>&1)"
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "vlass_run failed for ${ii}"
    echo "${output}"
    exit -1
  fi
  check_client_${ii}
done

# test the permutations that support a client-based implementation for VLASS
for ii in augment
do
  echo "Run ${ii} test case ..."
  run_dir=${RUN_ROOT}/${ii}

  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/*.jpg"
  cp $HOME/.ssl/cadcproxy.pem ${run_dir}
  docker run --rm -v ${run_dir}:/usr/src/app vlass_run_int vlass_run_single VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits /usr/src/app/cadcproxy.pem
  docker run --rm -v ${run_dir}:/usr/src/app vlass_run_int vlass_run_single VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.subim.fits /usr/src/app/cadcproxy.pem
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "vlass_run_single failed for ${ii}"
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
  docker run --rm -v ${run_dir}:/usr/src/app omm_run_int omm_run_single C170323_domeflat_K_CALRED /usr/src/app/cadcproxy.pem
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
  # output="$(docker run --rm -v ${run_dir}:/usr/src/app omm_run_int omm_run --todo ./abc.txt 2>&1)"
  docker run --rm -v ${run_dir}:/usr/src/app omm_run_int omm_run --todo ./abc.txt
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "omm_run failed for ${ii}"
    exit -1
  fi
  check_${ii}
done

# test those permutations that don't support the command-line parameter
for ii in failures scrape scrape_modify store_ingest_modify ingest_modify_local ingest_modify
do
  echo "Run ${ii} test case ..."
  run_dir=${RUN_ROOT}/${ii}
  cleanup_files "${run_dir}/logs/*.txt"
  cleanup_files "${run_dir}/logs/*.log"
  cleanup_files "${run_dir}/*.xml"
  cleanup_files "${run_dir}/*.jpg"

  output="$(docker run --rm -v ${run_dir}:/usr/src/app omm_run_int omm_run 2>&1)"
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
  check_${ii} "${output}"

done

date
exit 0
