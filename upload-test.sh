#!/bin/bash

generate_files() {
  for SIZE in 1 10 100 1000; do
    if [ "$1" = "MB" ]; then
      UNIT="M" 
    elif [ "$1" = "GB" ]; then
      UNIT="G"
    fi

    mkdir -p DATA
    FILE="DATA/file-random-contents-$SIZE$1.txt"
    #mkfile -n "$SIZE$UNIT" $FILE
    head -c "$SIZE$UNIT" </dev/urandom >$FILE
    echo "$FILE"...OK

  done
  echo
}

upload_files() {
  client=$2
  mkdir -p ./speed-tests
  log=./speed-tests/speed-test-$client-$(date +"%Y-%m-%dT%H:%M:%S%z").log

  echo -n "Upload Test: " > $log
  for BUCKET in "${1}"; do
    if [[ $client = "gen3" ]]; then
      gen3_upload SINGLEPART $log
      gen3_upload MULTIPART $log
    elif [[ $client = "mc" ]]; then
      mc_upload $log
    fi
  done

  echo >> $log
  echo -n "Download Test: " >> $log
  for BUCKET in "${1}"; do
    if [[ $client = "mc" ]]; then
      mc_download $log
    fi
  done
}

mc_upload() {
  log=$1
  echo "MinIO $BUCKET" >> $log

  for FILE in $(ls -1 -Sr DATA/*); do
    printf "Upload to $BUCKET: $FILE...\n"
    printf "%-6s%-2s" "$(stat -c%s $FILE | numfmt --to=iec)" >> $log

    time_cmd "mc cp $FILE $BUCKET" $FILE
  done
}

mc_download() {
  log=$1

  rm -rf ./download-tests/$BUCKET
  mkdir -p ./download-tests/$BUCKET
  echo "MinIO $BUCKET" >> $log
  for FILE in $(ls -1 -Sr DATA/*); do
    printf "Download from $BUCKET: $(basename $FILE)...\n"
    printf "%-6s%-2s" "$(stat -c%s $FILE | numfmt --to=iec)" >> $log
    FILE=$(basename $FILE)
    DEST="./download-test/$BUCKET/$FILE"
    time_cmd "mc cp $BUCKET/$FILE $DEST" $DEST
  done
}

time_cmd() {
    CMD=$1
    DEST=$2
    /usr/bin/time -f "%e" -o time.tmp $CMD
    printf "%s" "$(cat time.tmp)" >> $log
    bytes=$(stat -c%s $DEST)
    sec=$(cat time.tmp)
    echo -n "s   " >> $log

    speed=$(echo "scale=1; $bytes / 1000000 / $sec" | bc)
    printf "%s" "$speed" >> $log
    printf "MB/s\n" >> $log
    echo "OK"
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

if [[ $1 = "gen3" ]]; then
  client="gen3"
elif [[ $1 = "mc" ]]; then
  client="mc"
fi

upload_files "${BUCKETS[@]}" "$client"

#echo "Cleaning data files"
#clean_files
