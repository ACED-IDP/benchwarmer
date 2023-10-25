#!/bin/bash

generate_files() {
  for SIZE in 1 10 100 1000; do
    if [ "$1" = "MB" ]; then
      UNIT="m" 
    elif [ "$1" = "GB" ]; then
      UNIT="g"
    fi

    mkdir -p DATA
    FILE="DATA/file-random-contents-$SIZE$1.txt"
    mkfile -n "$SIZE$UNIT" $FILE
    echo "$FILE"...OK

  done
  echo
}

upload_files() {
  client=$2
  mkdir -p ./upload-tests
  log=./upload-tests/upload-test-$client-$(date +"%Y-%m-%dT%H:%M:%S%z").log
  echo "Upload Test $(date)\n" > $log

  for BUCKET in "${1}"; do
    if [ $client = "gen3" ]; then
      gen3_upload SINGLEPART $log
      gen3_upload MULTIPART $log
    elif [ $client = "mc" ]; then
      mc_upload $log
    fi
  done
}

mc_upload() {
  log=$1

  printf "MinIO Test" >> $log
  for FILE in $(ls -1 -Sr DATA/*); do
    printf "Uploading to $BUCKET: $FILE...\n"
    printf "%-6s%-2s" "$(stat -f%z $FILE | numfmt --to=iec)" >> $log

    CMD="mc cp $FILE $BUCKET"

    gtime -f "%e" -o time.tmp $CMD
    printf "%s" "$(cat time.tmp)" >> $log
    echo "s" >> $log
    echo "OK"
  done
  echo >> $log
  echo
}

gen3_upload() {
  log=$2
  GEN3_LOG="$HOME/.gen3/logs/development_succeeded_log.json"
  trash $GEN3_LOG &> /dev/null

  if [ "$1" = "SINGLEPART" ]; then
    FLAG=""
  elif [ "$1" = "MULTIPART" ]; then
    FLAG="--force-multipart"
  fi

  echo "Setting bucket to $BUCKET ($1)"
  echo "$BUCKET $1" >> $log

  for FILE in $(ls -1 -Sr DATA/*); do
    printf "Uploading to $BUCKET: $FILE..."
    printf "%-6s%-2s" "$(stat -f%z $FILE | numfmt --to=iec)" >> $log

    CMD="$HOME/go/bin/gen3-client upload $FLAG --profile=development \
         --bucket $BUCKET --upload-path ./$FILE"

    gtime -f "%e" -o time.tmp $CMD
    printf "%s" "$(cat time.tmp)" >> $log
    echo "s" >> $log
    echo "OK"
  done
  echo >> $log
  echo
}

clean_files() {
  python3 delete_unmapped_files.py -a https://development.aced-idp.org \
          -u beckmanl@ohsu.edu -c ~/.gen3/credentials.json
  #rm -rf ./DATA
  rm time.tmp
}

echo "Generating data files"
generate_files MB

BUCKETS=(
  # Cambridge
  "aced-cambridge-production/aced-cambridge-development"

  # AWS
  # "aced-development-ohsu-data-bucket"
  
  # # MinIO
  # "aced-ohsu-development"

  # # MinIO
  # "aced-ucl-development"

  # # Wasabi
  # "aced-wasabi-development"
)

echo "Uploading to buckets:"
for bucket in "${BUCKETS[@]}"
do
  echo "  $bucket"
done

if [ $1 = "gen3" ]; then
  client="gen3"
elif [ $1 = "mc" ]; then
  client="mc"
fi

upload_files "${BUCKETS[@]}" "$client"

#echo "Cleaning data files"
#clean_files
