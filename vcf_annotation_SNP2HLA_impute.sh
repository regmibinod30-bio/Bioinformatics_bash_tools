#!/bin/bash
# This script is written to annotate dbSNP rsID in .vcf files.Also implements
# SNP2HLA imputation. Make sure dbSNP file is available to the script. Put all
# reference files and executables in the script directory.

# sbatch options
#SBATCH --time=05:00:00
#SBATCH --mem=10g

# Redirect standard output to log file
LOGFILE='annotate_vcf.log'
exec 3>&1 4>&2 1>$LOGFILE 2>&1
echo "Job started at:$(date --rfc-3339=seconds)"

# Files and modules
module load bcftools/1.9 plink/1.9
dbsnp_data_file='/fdb/GATK_resource_bundle/hg19/dbsnp_138.hg19.vcf.gz'
input='input.vcf'

# Compress the input file and index
bgzip $input

# Index the file
tabix input.vcf.gz

# Annotate vcf file with dbsnp ID
bcftools annotate -c ID -a $dbsnp_data_file input.vcf.gz > input_rsID.vcf

# Load plink/1.07
module purge
module load plink/1.07

# SNP2HLA uses:
#./SNP2HLA DATA(.bim/.bed/.fam) REF output_file plink max_memory window_size
# Implement SNP2HLA implementation
./SNP2HLA input_rsID.vcf T1DGC_REF output plink 10000 1000
