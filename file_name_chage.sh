#!/bin/bash
# This script is written to change the file name in ATAC-seq pipeline input
# format
# written by Binod Regmi/NIH/NIAMS/BMDS
cd fq
for file in *_1.fastq.gz
    do
        base_name=`echo $file | sed -r 's/.{11}$//'`
        mv $file "s"$base_name"_r1.fq.gz"
    done

for file in *_2.fastq.gz
    do
        base_name=`echo $file | sed -r 's/.{11}$//'`
        mv $file "s"$base_name"_r2.fq.gz"
     done
cd ..
