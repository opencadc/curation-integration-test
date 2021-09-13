#!/bin/bash

# COLLECTIONS=( neossat gem omm vlass askap draost cgps vlite cfht dao )
COLLECTIONS=( neossat gem omm vlass draost cgps cfht dao phangs )

# provide a collection name as a parameter to 'run just one' set of
# unit tests
if [[ $# -eq 1 ]]
then
  test_set=( "${1}" )
else
  test_set=( ${COLLECTIONS[@]} )
fi

cadc_repo="opencadc"
omc_repo="opencadc"
opencadc_branch="master"

mkdir -p executions || exit $?
cd executions || exit $?

for collection in "${test_set[@]}"
do
  mkdir -p ${collection} || exit $?
  cd ${collection} || exit $?

  echo ":::retrieve Dockerfile for ${collection} from https://raw.github.com/${omc_repo}/${collection}2caom2/master/Dockerfile"
  curl -L https://raw.github.com/${omc_repo}/${collection}2caom2/master/Dockerfile -o Dockerfile || exit $?
  
  echo ":::docker build for ${collection}"
  sudo rm *xml 
  sudo rm *jpg 
  sudo rm *png 
  sudo rm *.fits* 
  sudo docker build -f Dockerfile --build-arg OPENCADC_BRANCH=${opencadc_branch} --build-arg OPENCADC_REPO=${cadc_repo} -t ${collection} ./ || exit $?

  echo "::: build ingest config"
  cp $HOME/.ssl/cadcproxy.pem . || exit $?
  cp ../../build_ingest_config.py . || exit $?
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} python build_ingest_config.py ${collection} || exit $?
  echo ""
  echo ""
  echo ""
  echo ":::docker run ${collection}_run empty todo"
  > todo.txt || exit $?
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} ${collection}_run || exit $?
  cp ../../prepare_run.py . || exit $?
  echo ""
  echo ""
  echo ""
  echo ":::prepare_run.py - get a single entry"
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} python prepare_run.py ${collection} || exit $?
  echo ""
  echo ""
  echo ""
  echo ":::docker run ${collection}_run SCRAPE MODIFY"
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} ${collection}_run || exit $?
  cp ../../compare_run.py . || exit $?
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} python compare_run.py ${collection} || exit $?
  echo ""
  echo ""
  echo ""
  echo ":::docker run ${collection}_run INGEST ${PWD}"
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} python build_ingest_config.py ${collection} || exit $?
  sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} ${collection}_run || exit $?
  if [[ ${collection} != "omm" ]]; then
    echo ""
    echo ""
    echo ""
    echo ":::docker run ${collection}_run_state INGEST"
    cp ../../build_state.py . || exit $?
    sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} python build_state.py ${collection} || exit $?
    sudo docker run --rm -v ${PWD}:/usr/src/app/ ${collection} ${collection}_run_state || exit $?
  fi
  cd .. || exit $?
  echo ":::${collection} Success at: $(date)" >> ../success_log.txt

done
cd .. || exit $?
exit 0
