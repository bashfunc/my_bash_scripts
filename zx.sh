#!/bin/bash

# in order to be able to do the change of the parent terminal, must be a function not a script
function zx() {
    if [ "$1" == "-h" ]; then
    echo "A bash script to change path according to the result of zg"
    echo "use: zx number"
    echo "ex : zx 4"
    exit 0
    fi

    # TODO: automate how to set the PATH_TO_SAVELAST and share it with zx
    PATH_TO_SAVELAST="/home/jrlab/Desktop/Git/MyBashScripts/Data/last_zg_output"

    SELECTED_COMMAND="cd $(head -$1 ${PATH_TO_SAVELAST} | tail -1 | cut -c 7-)"
    echo "${SELECTED_COMMAND}"
    eval ${SELECTED_COMMAND}
}