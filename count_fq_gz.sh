#!/bin/bash
# 12/14/11 by hws
# 2/19/13 modified by srb to accept an argument: file spec.
# count # of reads in a gz fq file
if [ $# -le 0 ]
then
  echo "usage: count_fq_gz.sh <filespec>"
  exit 1
fi
for i in $@
do
  # `` to make excutable, $[] to make calculations
  echo $i $[`gunzip -c $i | wc -l`/4]
done

