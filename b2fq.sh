#!/bin/bash
#
# Usage: b2fq.sh
#
#$ -N b2fq.sh
#$ -S /bin/sh
#$ -m e
#$ -M stephen.brooks@nih.gov
#$ -pe threaded 8
# The job is located in the current working directory.
#$ -cwd

module load bcl2fastq
bcl2fastq -R .. --sample-sheet ss.csv --output-dir .
exit

