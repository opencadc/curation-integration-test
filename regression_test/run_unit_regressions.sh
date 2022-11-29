#!/bin/bash

if [[ $# -ne 3 ]]; then
  echo "Usage: ${0} <lower case collection> <git organization name> <git branch name>"
  exit 1
fi

# COLLECTIONS=( neossat gem omm vlass askap draost cgps vlite cfht dao )
COLLECTIONS=( neossat gem omm vlass draost cgps cfht dao phangs )

# provide a collection name as a parameter to 'run just one' set of
# unit tests
# if [[ $# -eq 1 ]]
# then
#   test_set=( "${1}" )
# else
#   test_set=( ${COLLECTIONS[@]} )
# fi

test_set=( "${1}" )
git_repo="${2:-opencadc}"
git_branch="${3:-master}"

echo "Executing regression test for ${test_set} from ${git_repo}/${git_branch}"

mkdir -p executions || exit $?
cd executions || exit $?

for collection in "${test_set[@]}"
do
  cleans_up=$( python3 ${HOME}/regression/does_collection_clean_up.py ${collection} )
  data_mount=""
  mkdir -p ${collection} || exit $?
  cd ${collection} || exit $?

  if [[ ${cleans_up} == "1" ]]; then
    data_mount="-v ${PWD}/test_files:/data -v ${PWD}/test_files/success:/data/success -v ${PWD}/test_files/failure:/data/failure"
    mkdir -p "${PWD}/test_files"
    mkdir -p "${PWD}/test_files/success"
    mkdir -p "${PWD}/test_files/failure"
    echo "Using data mount ${data_mount}"
  fi

  if [[ ${git_branch} == "master" ]]; then
    echo ":::retrieve Dockerfile for ${collection} from https://raw.github.com/${git_repo}/${collection}2caom2/master/Dockerfile"
    curl -L https://raw.github.com/${git_repo}/${collection}2caom2/master/Dockerfile -o Dockerfile || exit $?
  else
    echo ":::retrieve Dockerfile for ${collection} from https://raw.github.com/${git_repo}/${collection}2caom2/raw/${git_branch}/Dockerfile"
    curl -L https://github.com/${git_repo}/${collection}2caom2/raw/${git_branch}/Dockerfile -o Dockerfile || exit $?
  fi

  echo ":::docker build for ${collection}"
  sudo rm *xml 
  sudo rm *jpg 
  sudo rm *png 
  sudo rm *.fits* 
  if [[ ${cleans_up} == "1" ]]; then
      sudo rm test_files/*.fits* 
      sudo rm test_files/success/*.fits* 
      sudo rm test_files/failure/*.fits* 
  fi
  sudo docker build -f Dockerfile --build-arg OPENCADC_BRANCH=${git_branch} --build-arg OPENCADC_REPO=${git_repo} -t ${collection} ./ || exit $?

  # the basis of every docker run command
  sudo_docker_run="sudo docker run --rm --user $(id -u):$(id -g) -e HOME=/usr/src/app -v ${PWD}:/usr/src/app/ ${data_mount} ${collection} "

  echo "::: build ingest config"
  cp $HOME/.ssl/cadcproxy.pem . || exit $?
  cp ../../build_ingest_config.py . || exit $?
  echo "${sudo_docker_run} python build_ingest_config.py ${collection}"
  ${sudo_docker_run} python build_ingest_config.py ${collection} || exit $?
  echo ""
  echo ""
  echo ""
  echo ":::docker run ${collection}_run empty todo"
  > todo.txt || exit $?
  echo "${sudo_docker_run} ${collection}_run"
  ${sudo_docker_run} ${collection}_run || exit $?
  cp ../../does_collection_clean_up.py . || exit $?
  cp ../../prepare_run.py . || exit $?
  cp ../../check_fitsverify.py . || exit $?
  echo ""
  echo ""
  echo ""
  echo ":::prepare_run.py - get a single entry"
  echo "${sudo_docker_run} python prepare_run.py ${collection}"
  ${sudo_docker_run} python prepare_run.py ${collection} || exit $?
  echo ""
  echo ""
  echo ""
  if [[ ${collection} != "gem" ]]; then
     # can't run gem2caom2 with SCRAPE
     echo ":::docker run ${collection}_run SCRAPE MODIFY"
     echo "${sudo_docker_run} ${collection}_run"
     ${sudo_docker_run} ${collection}_run || exit $?
     cp ../../does_collection_clean_up.py . || exit $?
     cp ../../compare_run.py . || exit $?
     echo "${sudo_docker_run} python compare_run.py ${collection}"
     ${sudo_docker_run} python compare_run.py ${collection} || exit $?
     echo ""
     echo ""
     echo ""
     echo "${sudo_docker_run} python check_fitsverify.py ${collection}"
     ${sudo_docker_run} python check_fitsverify.py ${collection}  || exit $?
     echo ""
     echo ""
     echo ""
  fi
  echo ":::docker run ${collection}_run INGEST ${PWD}"
  echo "${sudo_docker_run} python build_ingest_config.py ${collection}" 
  ${sudo_docker_run} python build_ingest_config.py ${collection} || exit $?
  echo "${sudo_docker_run} ${collection}_run"
  ${sudo_docker_run} ${collection}_run || exit $?
  if [[ ${collection} != "omm" ]]; then
    echo ""
    echo ""
    echo ""
    echo ":::docker run ${collection}_run_incremental INGEST"
    cp ../../does_collection_clean_up.py . || exit $?
    cp ../../build_state.py . || exit $?
    echo "${sudo_docker_run} python build_state.py ${collection}"
    ${sudo_docker_run} python build_state.py ${collection} || exit $?

    if [[ ${collection} == "gem" ]]; then
      echo "${sudo_docker_run} ${collection}_run_incremental"
      ${sudo_docker_run} ${collection}_run_incremental || exit $?
    else
      echo "${sudo_docker_run} ${collection}_run_state"
      ${sudo_docker_run} ${collection}_run_state || exit $?
    fi
  fi
  cd .. || exit $?
  echo ":::${collection} Success at: $(date)" >> ../success_log.txt

done
cd .. || exit $?
exit 0
