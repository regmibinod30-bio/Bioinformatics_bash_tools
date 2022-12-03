#!/bin/bash
# Script for running fastq-dump
# sbatch options
#SBATCH --time=05:00:00
#SBATCH --mem=10g

# Redirect standard output to log file
LOGFILE='annotate_vcf.log'
exec 3>&1 4>&2 1>$LOGFILE 2>&1
echo "Job started at:$(date --rfc-3339=seconds)"

# Module load
module purge
module load sratoolkit
module list

# download file
fastq-dump --origfmt --outdir data --gzip -A SRR2500883
mv data/SRR2500883.fastq.gz data/NFR1_CHIP_WT_1.fastq.gz

echo "job completed at:$(date --rfc-3339=seconds)"



