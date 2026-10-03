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

if [[ -z ${ARCHIVE_LIMIT} ]]; then
  printf "Please set the env variable ${RED}ARCHIVE_LIMIT${NC} to limit the number of archives to keep."
  printf "E.g. ARCHIVE_LIMIT=10\n"
  exit 0
fi

if [[ -z $1 ]]; then
  printf "Please pass one positional argument containing the absolute path to the game user data."
  printf "E.g. ~/Documents/Cemu/mlc/usr/save/00050000/101c9400/user/\n"
fi

bucket_path=${BUCKET_PATH}
archive_limit=${ARCHIVE_LIMIT}
path_to_game_user_dir=$1

printf "Navigating ${RED}${path_to_game_user_dir}${NC}\n"
pushd $path_to_game_user_dir

function navigate_back {
  popd
}
trap navigate_back EXIT

printf "Creating archive of ${RED}${path_to_game_user_dir}${NC}\n"
archive_name="game-data-$(date +"%Y-%m-%d-%H-%M-%S").zip"
zip -r $archive_name .

printf "Checking if the s3 bucket has more than ${RED}${archive_limit}${NC} files already.\n"
content=( $(aws s3 ls s3://$bucket_path/ | awk '{print $4}') )

if [[ ${#content[@]} -eq $archive_limit || ${#content[@]} -gt $archive_limit  ]]; then
  echo "There are too many archives. Deleting oldest one."
  # We can assume here that the list is in cronological order.
  printf "${RED}s3://${bucket_path}/${content[0]}\n"
  aws s3 rm s3://$bucket_path/${content[0]}
fi

printf "Uploading ${RED}${archive_name}${NC} to the s3 bucket.\n"
state=$(aws s3 cp $archive_name s3://$bucket_path/)

if [[ "$state" =~ "upload:" ]]; then
  printf "Backup ${LIGHT_GREEN}successful${NC}.\n"
  rm $archive_name
else
  printf "${RED}Error${NC} occured while uploading archive. Please investigate.\n"
fi
