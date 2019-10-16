#!/bin/bash
# a script to copy all the things from $I and $U to the github repo clone,
# to help me stay in sync on github
INT_DEST="$D/integration_test/int_test"
UNIT_DEST="$D/integration_test/unit_test"

echo "Copy shell scripts"
cp $T/*.sh $D/integration_test || exit $?
cp $I/*.sh $INT_DEST || exit $?
cp $U/*.sh $UNIT_DEST || exit $?

echo "Copy Dockerfiles"
cp $I/Dockerfile.* $INT_DEST || exit $?
cp $U/Dockerfile.* $UNIT_DEST || exit $?

echo "Copy expected observations."
cp $I/expected/* $INT_DEST/expected || exit $?

for ii in client_ingest_modify failures ingest ingest_modify ingest_modify_local ingest_modify_neossat retries scrape scrape_modify store_ingest_modify todo_parameter visit visit_cgps visit_gem vlass_state; do
    echo $ii
    mkdir -p $INT_DEST/$ii || exit $?
    cp $I/$ii/config.yml $INT_DEST/$ii || exit $?
    if [[ -e $I/$ii/state.yml ]]; then
        cp $I/$ii/state.yml $INT_DEST/$ii || exit $?
    fi
    if [[ -e $I/$ii/todo.txt ]]; then
        cp $I/$ii/todo.txt $INT_DEST/$ii || exit $?
    fi
done

exit 0
