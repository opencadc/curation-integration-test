#!/bin/bash

# COLLECTIONS=( neossat gem omm vlass askap draost cgps vlite cfht dao )
COLLECTIONS=( neossat gem omm vlass draost cgps cfht dao )

# provide a collection name as a parameter to 'run just one' set of
# unit tests
if [[ $# -eq 1 ]]
then
  test_set=( "${1}" )
else
  test_set=( ${COLLECTIONS[@]} )
fi

cadc_repo="SharonGoliath"
omc_repo="SharonGoliath"
opencadc_branch="master"

mkdir -p executions || exit $?
cd executions || exit $?

for collection in "${test_set[@]}"
do
  mkdir -p ${collection} || exit $?
  cd ${collection} || exit $?

  echo "retrieve Dockerfile for ${collection}"
  curl -L https://raw.github.com/${omc_repo}/${collection}2caom2/master/Dockerfile -o Dockerfile || exit $?
  
  echo "docker build for ${collection}"
  sudo docker build -f Dockerfile -t ${collection} ./ || exit $?

  echo "docker run ${collection}_run empty todo"
  > todo.txt || exit $?
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} ${collection}_run || exit $?
  cp ../../netrc . || exit $?
  cp ../../prepare_run.py . || exit $?
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} python prepare_run.py ${collection} || exit $?
  echo "docker run ${collection}_run one todo entry"
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} ${collection}_run || exit $?
  cp ../../compare_run.py . || exit $?
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} python compare_run.py ${collection} || exit $?
  cd .. || exit $?
  echo "${collection} Success at: $(date)" >> ../success_log.txt

done
cd .. || exit $?
exit 0
