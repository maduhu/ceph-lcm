#!/bin/bash
# Copyright (c) 2016 Mirantis Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -eu -o pipefail

COMPOSE_FILE="$(pwd)/docker-compose.yml"

while getopts "hp:f:" opt; do
  case $opt in
    h)
      echo "Restore Decapod database on _working_ containers."
      echo ""
      echo "This script obsoletes previous one. This restores native backup format."
      echo ""
      echo "${0} [-p projectname] [-f /path/to/docker-compose.yml] /path/to/backup" >&2
      exit 0
      ;;
    p)
      PROJECT_NAME="${OPTARG:-}"
      ;;
    f)
      COMPOSE_FILE="${OPTARG:-}"
      ;;
    \?)
      exit 1
      ;;
  esac
done

shift $(($OPTIND - 1))
if [ $# -eq 0 ]; then
    echo "You need to supply path to the database."
    exit 1
fi

COMPOSE_FILE="$(readlink -f "$COMPOSE_FILE")"
BACKUP_PATH="$(readlink -f "$1")"
PROJECT_NAME="${PROJECT_NAME:-${COMPOSE_PROJECT_NAME:-$(basename "$(dirname "$COMPOSE_FILE")")}}"
CONTAINER_NAME="$(docker-compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" ps -q admin | head -n 1)"

# TODO(sarkhipov): Cannot use docker-compose exec at the time of writing
# because of https://github.com/docker/compose/issues/3352
docker exec -i "$CONTAINER_NAME" decapod-admin db restore < "${BACKUP_PATH}"
