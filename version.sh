#Copyright 2022 AcquireCloud authors
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

#!/usr/bin/env bash

function check {
    code=$1;
    if [[ ${code} -ne 0 ]]; then
        echo "ERROR: $2"
        exit ${code}
    fi
}

function debug {
  if [ ${DEBUG} -ne 0 ]; then
      echo "DEBUG: $1"
  fi
}

function warning {
  if [ ${DEBUG} -ne 0 ]; then
    echo "WARNING: $1"
  fi
}

COMMIT="HEAD"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
DEBUG=0
SHORT_PRINT=0
while [[ "$1" != "" ]]; do
    case $1 in
        -h|--help)
            cat <<EOT
USAGE: version.sh [options]

    version.sh prints the product version for a git revision(commit).

    The product version has the following format: v<MAJOR>.<MINOR>.<PATCH>[-<BRANCH>]
The version in general complies the semantic version (https://semver.org) rules. The version.sh will
look for the "nearest" tag, which should have the format v<MAJOR>.<MINOR>.<PATCH>. It will calculate
the distance between the tag and the provided revision(commit) and adjust the <PATCH> number from
the tag version.

OPTIONS:
    -b, --branch            specify the branch name for the version. Default value is current branch name. if the branch
                            name is not 'main', then the result version will contain the suffix with the branch name.
    -c, --commit            will build the version for the commit.
    -h, --help              prints the help
    -s, --short             prints the semantic version only. Doesn't print the commit # in the stdout.
    -v, --verbose           be more verbose.

EOT
            exit 0
            ;;
        -v|--verbose)
            DEBUG=1
            ;;
        -b|--branch)
            shift
            BRANCH=$1
            ;;
        -s|--short)
            SHORT_PRINT=1
            ;;
        -c|--commit)
            shift
            COMMIT=$1
            ;;
        *)
            echo "Error: Unknown argument $1 passed! Try --help ..."
            exit 1
            ;;
    esac
    shift
done

debug "Running with:"
debug "    BRANCH=${BRANCH}"
debug "    COMMIT=${COMMIT}"
debug "    SHORT_PRINT=${SHORT_PRINT}"

# looking for the closest tag to the commit
GIT_VER=$(git describe --tags --long  --match v[0-9].* ${COMMIT})
check $? "could not obtain tag(s) in the chain for the commit ${COMMIT}. Has the repo been ever tagged?"
debug "git describe found closest tag: ${GIT_VER}"

IFS='-' # set '-' as a delimiter
read -ra PARTS <<< "$GIT_VER" # GIT_VER is read into an array as tokens separated by IFS

if [ ${#PARTS[@]} != "3" ]; then
    check 1 "expected version in format vMAJOR.MINOR.PATCH-DISTANCE-COMMIT, but got ${GIT_VER}"
fi
debug "the tag is ${PARTS[0]}, with ${PARTS[1]} revisions behind the commit"

IFS='.' # set '.' as a delimiter
read -ra BASE_VERS <<< "${PARTS[0]}" # PARTS[0] is read into an array as tokens separated by IFS

if [ ${#BASE_VERS[@]} != "3" ]; then
    check 1 "expected tag in format vMAJOR.MINOR.PATCH, but got ${PARTS[0]}"
fi

# obtaining full commit number
COMMIT=$(git rev-parse ${PARTS[2]:1})
debug "the revision is ${COMMIT} obtained by ${PARTS[2]:1}"

$(git branch --contains ${COMMIT}|grep ${BRANCH} > /dev/null 2>&1)
check $? "seems like the commit ${COMMIT} is not on the branch ${BRANCH}"

SUFFIX=""
if [ "${BRANCH}" != "main" ]; then
  SUFFIX="-${BRANCH}"
  debug "the branch ${BRANCH} is not main one, will apply suffix ${SUFFIX}"
fi

if [ -n "$(git status --porcelain)" ]; then
    SUFFIX="${SUFFIX}-uncommitted"
    debug "WARNING: found uncommitted changes on the branch ${BRANCH}"
fi

# calculate the PATCH number
PATCH=$((${BASE_VERS[2]} + ${PARTS[1]}))

if [ ${SHORT_PRINT} -ne 0 ]; then
  debug "the build version number only:"
  # print the version number only
  echo "${BASE_VERS[0]}.${BASE_VERS[1]}.${PATCH}${SUFFIX}"
else
  debug "the build version number and the build commit:"
  # print the version and commit number
  echo "${BASE_VERS[0]}.${BASE_VERS[1]}.${PATCH}${SUFFIX} ${COMMIT}"
fi
