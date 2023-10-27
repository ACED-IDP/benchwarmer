# benchwarmer

Benchmarking tool used to test upload speeds of the gen3-client and MinIO endpoints

## Quick Start

Speed tests using the `mc` client:

```sh
➜ ./upload-test.sh mc
```

Speed tests using the `gen3-client` command:

```sh
➜ ./upload-test.sh gen3
```

## Example Run (MinIO Upload/Download)

```sh
➜ ./upload-test.sh mc
Generating data files
DATA/file-random-contents-1MB.txt...OK
DATA/file-random-contents-10MB.txt...OK
DATA/file-random-contents-100MB.txt...OK
DATA/file-random-contents-1000MB.txt...OK

Uploading to buckets:
  aced-cambridge-production/aced-cambridge-development
Upload to aced-cambridge-production/aced-cambridge-development: DATA/file-random-contents-1MB.txt...OK
Upload to aced-cambridge-production/aced-cambridge-development: DATA/file-random-contents-10MB.txt...OK
Upload to aced-cambridge-production/aced-cambridge-development: DATA/file-random-contents-100MB.txt...OK
Upload to aced-cambridge-production/aced-cambridge-development: DATA/file-random-contents-1000MB.txt...OK
Download from aced-cambridge-production/aced-cambridge-development: file-random-contents-1MB.txt...OK
Download from aced-cambridge-production/aced-cambridge-development: file-random-contents-10MB.txt...OK
Download from aced-cambridge-production/aced-cambridge-development: file-random-contents-100MB.txt...OK
Download from aced-cambridge-production/aced-cambridge-development: file-random-contents-1000MB.txt...OK
```

## Example Output

```
Upload Test: MinIO aced-cambridge-production/aced-cambridge-development
1.0M    4.56s    .2MB/s
10M     4.21s    2.4MB/s
100M    8.10s    12.9MB/s
1000M   39.63s   26.4MB/s

Download Test: MinIO aced-cambridge-production/aced-cambridge-development
1.0M    3.80s    .2MB/s
10M     4.52s    2.3MB/s
100M    8.48s    12.3MB/s
1000M   47.89s   21.8MB/s
```

## TODO

- Add download speed test support for gen3-client
- More user flags (e.g. file generation)
- Convert shell script to Python for ease of development 
