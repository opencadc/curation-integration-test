#!/bin/bash

ROOT_DIR="/Volumes/Development"
DEV_DIR="${ROOT_DIR}/dev"
RUN_ROOT=${ROOT_DIR}/test/int_test
ACTUAL=${RUN_ROOT}/actual

CGPS_ROOT=${DEV_DIR}/cgps2caom2
DRAOST_ROOT=${DEV_DIR}/draost2caom2
GEM_ROOT=${DEV_DIR}/gem2caom2
GMIMS_ROOT=${DEV_DIR}/draogmims2caom2
NEOS_ROOT=${DEV_DIR}/neossat2caom2
OMM_ROOT=${DEV_DIR}/omm2caom2
VLASS_ROOT=${DEV_DIR}/vlass2caom2

CONT_ROOT="/usr/src/app"
UNIT_COMMON="unit_common"
UNIT_MATPLOTLIB="unit_matplotlib"
UNIT_PANDAS="unit_pandas"
UNIT_CAOM2PIPE="unit_caom2pipe"
INT_COMMON="int_common"
INT_MATPLOTLIB="int_matplotlib"
INT_PANDAS="int_pandas"

# stop if a file has any content
file_is_zero() {
  if [[ -e  ${1} ]]
  then
    if [[ ! -s ${1} ]]
    then
      echo "${1} not generated."
      exit 1
    fi
  else
    echo "${1} should exist."
    exit 1
  fi
}

# stop if a file doesn't have content
file_is_not_zero() {
  if [[ -e  ${1} ]]
  then
    if [[ -s ${1} ]]
    then
      echo "${1} generated."
      exit 1
    fi
  else
    echo "${1} should exist."
    exit 1
  fi
}

# stop if a file exists
file_exists() {
  if [[ -e  ${1} ]]
  then
    echo "${1} should not exist."
    exit 1
  fi
}

# stop if a file has specific content
file_has_content() {
  if grep "${1}" "${2}"
  then
    echo "${1} not expected in ${2}."
    exit 1
  fi
}

# stop if a file does not have specific content
file_does_not_have_content() {
  if ! grep "${1}" "${2}"
  then
    echo "${1} expected in ${2}."
    exit 1
  fi
}

# stop if a directory does not exist
directory_does_not_exist() {
  if [[ ! -d  ${1} ]]
  then
    echo "${1} should exist and should be a directory."
    exit 1
  fi
}

check_observation_in_db() {
  collection="${1}"
  obs_id="${2}"
  image="${3}"
  xml="${obs_id}.xml"
  actual_outside_container="${RUN_ROOT}/actual/${xml}"
  actual="${CONT_ROOT}/actual/${xml}"
  expected="${CONT_ROOT}/expected/${xml}"
  output=$(caom2-repo read --cert ${HOME}/.ssl/cadcproxy.pem --resource-id ivo://cadc.nrc.ca/sc2repo ${collection} ${obs_id} > ${actual_outside_container} )
  result=$?
  if [[ ${result} -ne 0 ]]
  then
    echo "caom2-repo failed for ${obs_id}"
    echo "${output}"
    exit 1
  fi
  echo "docker run --rm -v ${RUN_ROOT}:${CONT_ROOT} ${image} python compare_observations.py ${expected} ${actual} 2>&1"
  # output=$(docker run --rm -v ${RUN_ROOT}:${CONT_ROOT} ${image} python compare_observations.py ${expected} ${actual} 2>&1)
  if [[ ${result} -ne 0 ]]
  then
    echo "compare_observations execution failed for ${obs_id}"
    echo "${output}"
    exit 1
  fi
  if [[ "${#output}" -gt 0 ]]
  then
    echo "compare_observations failed for ${obs_id}"
    echo "${output}"
    exit 1
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
  echo "check_failures"
  failure_log="${RUN_ROOT}/failures/logs/failure_log.txt"
  file_is_zero ${failure_log}
}

check_scrape() {
  echo "check_scrape"
  echo "${1}"
  failure_log="${RUN_ROOT}/scrape/logs/failure_log.txt"
  success_log="${RUN_ROOT}/scrape/logs/success_log.txt"
  xml="${RUN_ROOT}/scrape/C170324_0054_SCI.fits.xml"
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
  obs_id="C180616_0135_SCI"
  check_observation_in_db OMM ${obs_id} omm_run_int
}

check_ingest_modify_local() {
  check_dir="${RUN_ROOT}/ingest_modify_local"
  failure_log="${check_dir}/logs/failure_log.txt"
  success_log="${check_dir}/logs/success_log.txt"
  xml="${check_dir}/C080121_0339_SCI.fits.xml"
  prev="${check_dir}/C080121_0339_SCI_prev.jpg"
  thumb="${check_dir}/C080121_0339_SCI_prev_256.jpg"
  file_is_not_zero ${failure_log}
  file_is_zero ${success_log}
  file_is_zero ${xml}
  file_is_zero ${prev}
  file_is_zero ${thumb}
  # caom2repo service is working
  xml="${check_dir}/C080121_0339_SCI.fits.xml"
  #
  # this file will not have footprintfinder results, because there
  # is no WCS in it - but check to make sure that is what's
  # actually happening, and that the log message is doing the output
  #
  log="${check_dir}/logs/C080121_0339_SCI.log"
  txt="${check_dir}/logs/C080121_0339_SCI_footprint.txt"
  file_does_not_have_content "caom2:metaChecksum" ${xml}
  # file_does_not_have_content "footprint generation" ${log}
  file_is_zero ${txt}
  obs_id="C080121_0339_SCI"
  check_observation_in_db OMM ${obs_id} omm_run_int
  obs_id="C180108_0002_SCI"
  check_observation_in_db OMM ${obs_id} omm_run_int
}

check_ingest_modify() {
  echo "check_ingest_modify"
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
  obs_id="C170323_domeflat_K_CALRED"
  check_observation_in_db OMM ${obs_id} omm_run_int
  obs_id="C120213_0004_REJECT"
  check_observation_in_db OMM ${obs_id} omm_run_int
  obs_id="C100521_domeflat_K_CALRED"
  check_observation_in_db OMM ${obs_id} omm_run_int
}

check_ingest_modify_neossat() {
  echo "check_ingest_modify_neossat"
  failure_log="${RUN_ROOT}/ingest_modify_neossat/logs/failure_log.txt"
  success_log="${RUN_ROOT}/ingest_modify_neossat/logs/success_log.txt"
  fname="2019213215700"
  xml="${RUN_ROOT}/ingest_modify_neossat/logs/${fname}.fits.xml"
  file_is_not_zero ${failure_log}
  file_is_zero ${success_log}
  file_is_zero ${xml}
  obs_id="2019213215700"
  check_observation_in_db NEOSSAT ${obs_id} neossat_run_int
}

check_client_ingest() {
  echo "check_client_ingest"
  fname=" VLASS1.1.ql.T01t01.J000228-363000.10.2048.v1.I.iter1.image.pbcor.tt0.rms.subim.fits"
  xml="${RUN_ROOT}/ingest/VLASS1.1.T01t01.J000228-363000.xml"
  file_exists ${xml}
  obs_id="VLASS1.1.T01t01.J000228-363000"
  check_observation_in_db VLASS ${obs_id} vlass_run_int
  obs_id="VLASS1.1.T10t12.J075402-033000"
  check_observation_in_db VLASS ${obs_id} vlass_run_int
}

check_client_ingest_modify() {
  echo "check_client_ingest_modify"
  failure_log="${RUN_ROOT}/client_ingest_modify/logs/failure_log.txt"
  success_log="${RUN_ROOT}/client_ingest_modify/logs/success_log.txt"
  fname="C170323_domeflat_K_CALRED"
  xml="${RUN_ROOT}/client_ingest_modify/${fname}.fits.xml"
  prev="${RUN_ROOT}/client_ingest_modify/${fname}_prev.jpg"
  thumb="${RUN_ROOT}/client_ingest_modify/${fname}_prev_256.jpg"
  file_exists ${failure_log}
  file_exists ${success_log}
  file_exists ${xml}
  file_exists ${prev}
  file_exists ${thumb}
  obs_id="C170323_domeflat_K_CALRED"
  check_observation_in_db OMM ${obs_id} omm_run_int
}

check_todo_parameter() {
  echo "check_todo_parameter"
  failure_log="${RUN_ROOT}/todo_parameter/logs/abc_failure_log.txt"
  success_log="${RUN_ROOT}/todo_parameter/logs/abc_success_log.txt"
  file_is_zero ${failure_log}
  file_is_not_zero ${success_log}
}

check_client_visit() {
  echo "check_client_visit"
  failure_log="${RUN_ROOT}/visit/logs/failure_log.txt"
  success_log="${RUN_ROOT}/visit/logs/success_log.txt"
  obs_id="VLASS1.1.T01t01.J000228-363000"
  file_is_not_zero ${failure_log}
  file_is_zero ${success_log}
  check_observation_in_db VLASS ${obs_id} vlass_run_int
}

check_client_visit_cgps() {
  echo "check_client_visit_cgps"
  failure_log="${RUN_ROOT}/visit_cgps/logs/failure_log.txt"
  success_log="${RUN_ROOT}/visit_cgps/logs/success_log.txt"
  obs_id="VLASS1.1.T01t01.J000228-363000"
  file_is_not_zero ${failure_log}
  file_is_not_zero ${success_log}
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
  cleanup_files "${2}/*.md"
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
  if [[ -e ${1}/data ]]
  then
    mkdir -p ${2}/data || exit $?
    cp ${1}/data/* ${2}/data || exit $?
  fi
  if [[ -e ${1}/scripts ]]
  then
    mkdir -p ${2}/scripts || exit $?
    cp ${1}/scripts/* ${2}/scripts || exit $?
  fi
}


docker_cleanup() {
  echo "docker clean up, before running out of space"
  echo "remove stopped images"
  output=$(docker ps -a -f status=exited -q)
  if [[ ! -z "${output}" ]]
  then
    for ii in ${output}
    do
      docker rm ${ii} || exit $?
    done
  fi

  output=$(docker ps -a -f status=created -q)
  if [[ ! -z "${output}" ]]
  then
    for ii in ${output}
    do
      docker rm ${ii} || exit $?
    done
  fi

  echo "delete unused images"
  output=$(docker images -qf "dangling=true")
  if [[ ! -z "${output}" ]]
  then
    for ii in ${output}
    do
      docker rmi ${ii} || exit $?
    done
  fi
}

build_int_common()
{
  echo "Copy common source"
  copy_pip_install ${D}/caom2pipe caom2pipe caom2pipe
  for container in $INT_COMMON $INT_MATPLOTLIB $INT_PANDAS
  do
    echo "Build container ${container}"
    output="$(docker build -f ${I}/Dockerfile.${container} -t ${container} ./ 2>&1)"
    result=$?
    if [[ ${result} -ne 0 ]]
    then
      echo "${output}"
      echo "docker build failed for ${container}"
      exit 1
    fi
  done
}

cleanup_metrics()
{
  _metrics_dir="${1}/metrics"
  if [[ -e ${_metrics_dir} ]]
  then
    echo "clean up metrics directory"
    cleanup_files "${_metrics_dir}/*.yml"
    sudo rmdir ${_metrics_dir} || exit $?
  fi
}
