#!/bin/bash
# This script is written to export genotype data from Illumina GenomeStudio
# FinalReport.txt to plink bed file. Implement this script step by step. 

# NOTE: plink is memory hungry for implementing .lgen conversion.It requires
# 100g plus max_memory in some steps of the implementation.

# NOTE: I colleted all the commands I implemented so far and created this
# script. There is a slim change that it contains minor syntax errors which can
# be easily fixed. I have never run this script all at a time.

# Job script
#SBATCH -o Illumi_2_plink
#SBATCH --time=05:00:00
#SBATCH --mem=200g
  
LOGFILE='illumina_2_plink.log'
echo "directing standard output to log file"
exec 3>&1 4>&2 1>$LOGFILE 2>&1

# Modules
module purge
module load plink/1.9
module list

# Illumina data file
data='FinalReport.txt'

# NOTE: header lines should be removed in FinalReport.txt file.

# Create .lgen file for imputing genotypes to plink
awk -v OFS="\t" '{print $2, $2, $1, $6, $7}' $data > data.lgen

# Note plink needs missing genotype (-) replaced by (0) in .lgen file
awk -v OFS="\t" '{$4 == "-" ? 0:$4}1' data.lgen > temp_1_data.lgen
awk -v OFS="\t" '{$5 == "-" ? 0:$5}1' temp_1_data.lgen > temp_2_data.lgen

# Clean up
rm -rf data.lgen temp_1_data.lgen
mv temp_2_data.lgen data.lgen

# Create map file for imputing snp id and chr physical position
awk -v OFS="\t" '{$12, $1, 0, $13}' $data > with_duplicate.map

# The above map file has duplications, remove it
# The total rows in map file should be (data.lgen(n of row))/(# samples)
awk '!a[$2]++' with_duplicate.map > data.map
rm -rf with_duplicate.map

# Create .fam file for plink input
awk -v OFS="\t" '{ print $2, $2, 0, 0, 0, -9}'$data > with_duplicate.fam

# Remove duplicates, .fam file n-rows should of equal to sample size
awk -v OFS="\t" '{$4 == "-" ? 0:$4}1' with_duplicate.fam > data.fam

# Convert the .lgen files into ped/bed file using plink
plink --lfile data --recode --out data
plink --file data --make-bed --out illumina_2_plink

