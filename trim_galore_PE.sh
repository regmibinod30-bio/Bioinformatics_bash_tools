#!/bin/bash
# 
# note
# 1. module: trimgalore, but run as trim_galore
# 2. even though it doesn't have a -p option, it seems to run multiple threaded, use '-t 10' with swarm
#   swarm -t 10 -g 10 -f trim.sw --time=12:00:00

for i in /data/Gourh_Lab/Julia/raw_data/C*/*_1.fq.gz
do
  echo module load fastqc trimgalore\; trim_galore --fastqc -o trimmed_fqgz --paired $i ${i/_1/_2}
done

