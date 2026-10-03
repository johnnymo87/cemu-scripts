#! /usr/bin/env bash

set -euo pipefail

RED=''
LIGHT_GREEN=''
NC=''

if [[ -t 1 ]]; then
    colors=$(tput colors)
    if [[ $colors ]]; then
        RED='\033[0;31m'
        LIGHT_GREEN='\033[1;32m'
        NC='\033[0m'
    fi
fi

if [[ -z ${BUCKET_PATH} ]]; then
  printf "Please set the env variable ${RED}BUCKET${NC} to the s3 bucket name."
  printf "E.g. BUCKET_PATH=my-bucket/breath-of-the-wild/jonathan\n"
  exit 0
fi

if [[ -z ${ARCHIVE_NAME} ]]; then
  printf "Please set the env variable ${RED}ARCHIVE_NAME${NC} to the file in the s3 bucket."
  printf "E.g. game-data-2023-01-08-13-50-20.zip\n"
  exit 0
fi

if [[ -z $1 ]]; then
  printf "Please pass one positional argument containing the absolute path to restore the game user data to."
  printf "E.g. ~/Documents/Cemu/mlc/usr/save/00050000/101c9400/user/\n"
fi

bucket_path=${BUCKET_PATH}
archive_name=${ARCHIVE_NAME}
path_to_game_user_dir=$1

printf "Navigating ${RED}${path_to_game_user_dir}${NC}\n"
pushd $path_to_game_user_dir

function navigate_back {
  popd
}
trap navigate_back EXIT

printf "Downloading ${RED}${archive_name}${NC} from the s3 bucket.\n"
aws s3 cp s3://$bucket_path/$archive_name $archive_name

printf "Restoring ${RED}${archive_name}${NC} to ${RED}${path_to_game_user_dir}${NC}.\n"
unzip $archive_name -d $path_to_game_user_dir

printf "Restore ${LIGHT_GREEN}successful${NC}.\n"

rm $archive_name
