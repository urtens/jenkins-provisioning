#!/bin/bash

set -e

REPOS_FILE=${REPOS_FILE:-/usr/share/jenkins/data/repos.txt}
TEMP_REPOS_DIR="/tmp/repos"
JOBDSL_DIR="${TEMP_REPOS_DIR}/jobdsl"

echo "$(date) START JENKINS SETUP"

rm -rf "${TEMP_REPOS_DIR}"
mkdir -vp "${TEMP_REPOS_DIR}"

# Get job dsl files from git repos
if [ -f "${REPOS_FILE}" ]; then
    echo "${REPOS_FILE} found!"
    cat "${REPOS_FILE}"
    rm -f "${JOBDSL_DIR}/*"
    mkdir -vp "${JOBDSL_DIR}"
    count=0
    while IFS='' read -r repo || [[ -n "$repo" ]]; do
        # To speed up grabbing of jobdsl files in bitbucket (github doesnt support archive!!)
        if [[ "$repo" = *"bitbucket.org"* ]]; then
            repo=$(echo "${repo}" | tr ":" "/")
             git archive --remote="ssh://git@${repo}.git" HEAD "${repo##*/}.jobdsl" | tar xvf - -C "${JOBDSL_DIR}"
        else
             git clone -n --depth 1 "git@${repo}" "${TEMP_REPOS_DIR}/${repo#*/}"
             (cd "${TEMP_REPOS_DIR}/${repo#*/}" && git checkout HEAD "${repo#*/}.jobdsl")
        fi
        echo "Repo ordered as $((count++)) to process"
        mv "${TEMP_REPOS_DIR}/${repo#*/}/${repo#*/}.jobdsl" "${TEMP_REPOS_DIR}/${repo#*/}/${count}_${repo#*/}.jobdsl"
    done < "${REPOS_FILE}"
    cd "${TEMP_REPOS_DIR}"
    find . -name \*.jobdsl -exec mv -v {} "${JOBDSL_DIR}" \;
else
    echo "${REPOS_FILE} does not exist, this should be mounted in"
fi
