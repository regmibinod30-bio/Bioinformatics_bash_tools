#!/bin/bash

# =========================
# gtex_data_mining_pipeline
# =========================

# This bash script is written to automatize extraction of GETx data of a gene of
# interest.It requires perl, plink and VCFtools available in the module 
# environment.

# Pravitt's Instruction
# **********************
# Input files would be- GTEx genotyping data or GTEx WGS data, GTEx RNA-Seq
# data, Demographic information (gender, race), and Sample & Tissue ID Code
# Options Filter- Gender, Race, Chr:position filter range for SNPs within that
# region, Chr:position filter for RNA-Seq data or it could be that you enter a
# gene symbol and it pulls out +-1MB data
# ***********************

# Required input files for the script
# ***********************************
# Before implementing the script, make sure these data directories are
# available to the script in the SCRIPT DIRECTORY:
#           1. genotypes_data: Provide vcf file of the chromosome of interest.
#              It should be unzipped and placed inside genotypes directory.
#           2. genotypes_dir: This directory contains genotypes_data file
#           3. expression_data: This directory contains RNA expression data of
#              the tissues (.bed files).
#           4. demographic_data : provide sex,gender,age etc data file within
#              demographic_data directory. IMPORTANT:The file inside
#              demographic_data directory must be named 'GTEx_phenotypes.txt'
#           5. chr_num='#' provide chr#. For example, if the gene of interest
#              is found in chromosome 6, put chr_num='6'
#           6. gene_ID: Provide ENSEMBL gene ID starting with 'ENSG*'
#           7. chr_ID='chr#' provide chr_ID. For example, if the gene of
#              interest is in chromosome 6, put chr_ID='chr6'

# Running the script
# ******************
# Place this script in the script directory. Provide data files and directories
# mentioned above in the script directory. Implement the script using following
# command in biowulf or available computer cluster.

#           >sbatch gtex_data_mining_pipeline.sh

# Output files
# ***************
# All output files are directed to output directory. The output contains one
# subdirectory for each GTEX tissue type. The subdirectory contains following
# files:

# 1. {tissue_name}.covariates.txt: This matrix contains five rows with GTEx
# subject_ID, sex, age and race. The size of the matrix varies according to
# tissue type. 

# 2. {tissue_name}.geneloc.txt: This matrix contains location of all genes 
# within 1mb region.

# 3. {tissue_name}.GE.txt: This matrix contains gene expression data within
# 1 mb genome region.

# 4. {tissue_name}.snpsloc.txt: This matrix contains SNPs location data within
# 1 mb region.

# 5. {tissue_name}.snp.txt: This matrix contains list of SNPs for the samples.

# The script produces a large log file that is directed in the script
# directory. It is hard to capture error message in log file. I recommend use
# grep 'ERROR' <file.log> or grep 'error' <file.log> to catch the error
# message.

# Estimated computation time
# *****************************


# Job script
# **********
#SBATCH --time=02:00:00
#SBATCH --mem=20g

# Redirect standard output to log file
# Stamp the job start time
LOGFILE='gtex_data_mining_pipeline.log'
exec 3>&1 4>&2 1>$LOGFILE 2>&1
echo "Job started at:$(date --rfc-3339=seconds)"

# Module load
module purge
module load plink vcftools
module list

# =====================================
# IMPORTANT: Provide data files and directories and thier path to following
# section
# ====================================
# Directries and files
genotypes_dir='genotypes_matrix'
genotypes_data='chr10.vcf'
expression_data='expression_matrix_2'
demographic_data='covariates/GTEx_phenotypes.txt'
chr_num='10'
chr_ID='chr10'
gene_ID='ENSG00000178473.6'

# Check if data directories exits
# Check if data directories exits
if [[ -d "$genotypes_dir"  && -d "$expression_data" && -f "$demographic_data" ]]
        then
            echo "data directories exist, checking the gene_ID and chr_num....."
        else
            echo "USERS ERROR: data directories do not exist. Exiting.........."
            exit
fi

# Check if variables are defined
# Just check the variables are empty or not
if [[ -n "$chr_num" && -n "$gene_ID"  && -n "chr_ID" ]]
        then
            echo "Chromosome number and gene_Id specified...implementing \
            the next step.."
        else
            echo "Users ERROR: Required variables are not defined. \
            Exiting........"
        exit
fi

# Extract the gene location file (*.geneloc.txt)
# Extract the gene expressin data(*.GE.txt)
echo "******extracting the gene_ID of interest******"
cd $expression_data
for file in *.v8.normalized_expression.bed
    do
       tissue_name=`echo $file | sed -r 's/.{29}$//'`
       awk -v OFS='\t' 'BEGIN { print "gene_id   chr left  right"} \
       {if ($4~'/$gene_ID/') {print $4, $1, $2, $3}}' $file \
       > "$tissue_name".geneloc.txt
                   
       cut -f1,2,3  --complement $file > "$file".txt 
       cut -f1 "$file".txt --complement | head -1 > \
        "$tissue_name".sample_name.txt
       
       head -1 "$file".txt > "$tissue_name".GE.txt
       awk -v OFS='\t' '{if ($1~'/$gene_ID/') {print $0}}' "$file".txt \
       >> "$tissue_name".GE.txt 
       rm -rf "$file".txt
    done
echo "*******gene_ID extraction completed******"

# Delete files that do not contain expression data
for file in *.GE.txt
    do
        line_numbers=$(wc -l < $file)
        if [ $line_numbers -lt  2 ];
        then
        rm $file
        fi
    done

# Delete files that do not contain gene location information
for file in *.geneloc.txt
    do
        line_numbers=$(wc -l < $file)
        if [ $line_numbers -lt 2 ];
        then 
            rm $file
        fi
done

# List the tissues expressing the given gene (gene_ID)
for file in *.GE.txt
    do
        tissue_name=`echo $file | sed -r 's/.{7}$//'`
        echo "$tissue_name" >> List_of_tissue_with."$gene_ID".expressed
    done


# Extract sample vector for each tissue type
echo "****** extracting sample vectors******"
for file in *.sample_name.txt
    do
        tissue_name=`echo $file | sed -r 's/.{16}$//'`
        awk '{for (i=1; i<=NF; i++) print $i}' $file | sort \
        > "$tissue_name".sample.vector.txt 
    done
echo "****** sample vector extraction completed******"

# Extract demographic data
# The file must be named GTEx_phenotypes.txt
cd ..
cp $demographic_data $expression_data/.
cd $expression_data

# Remove the header of expression data
# Extract SUGJECT_ID, SEX, AGE, Race columns from demographic data
echo "****** extracting demographic data******"
sed '1d' GTEx_phenotypes.txt | awk -v OFS='\t' \
'{print $2, $4, $5, $6}' | sort > phenotypes.txt

for file in *.sample.vector.txt
    do
        tissue_name=`echo $file | sed -r 's/.{18}$//'`
        join -1 1 -2 1 "$file" phenotypes.txt \
        > "$tissue_name".demographic.txt
           
    done
echo "demographic data extraction completed******"

# Extract SNPs data
cd ..
cd $genotypes_dir
plink --vcf $genotypes_data --make-bed --out $genotypes_data
cp -r "$genotypes_data".* ../$expression_data/.
rm -rf "$genotypes_data".*
cd ..
cd $expression_data

# Map the genome position to extract 1mb genotypes data
x=$(awk 'NR==2 {print $3}' *.geneloc.txt)
if [[ $x -le 500000 ]]
then
    top=$x
    buttom=$(( $x + 1000000 ))
else
    top=$(( $x - 500000 ))
    buttom=$(( $x + 500000 ))
fi
echo "x: $x"
echo "top: $top"
echo "buttom: $buttom"

# Extract the SNPs from a range of chromosome position
plink --bfile $genotypes_data --chr $chr_num --from-bp $top --to-bp $buttom \
--make-bed --out "$genotypes_data".extract

# Make a keep.txt file for extracting individuals using plink
for file in *.sample.vector.txt
    do
        tissue_name=`echo $file | sed -r 's/.{18}$//'`
        awk -v OFS='\t' '{print $1, $1}' $file > "$tissue_name".sample_subsets.txt
    done

# Extract vcf file for each sample vector
for file in *.sample_subsets.txt
    do
        tissue_name=`echo $file | sed -r 's/.{19}$//'`
        plink --bfile "$genotypes_data".extract --keep $file --recode vcf \
        --out $tissue_name
        vcftools --vcf "$tissue_name".vcf --extract-FORMAT-info GT \
        --out "$tissue_name"
    done

# Extract SNPs and SNPs location file from the gene region
echo "****** SNPs location file extraction started*******"
for file in *.GT.FORMAT
    do
        tissue_name=`echo $file | sed -r 's/.{10}$//'`
        awk '{$1=$1":"$2; $2=""; print $0}' $file > "$tissue_name".output_SNP.txt
        perl -pe 's!0/0!0!g; s!0/1!1!g; s!1/1!2!g; s!./.!NA!g, s!CHROM:POS!snpid!g' \
        "$tissue_name".output_SNP.txt > "$tissue_name".SNP.txt
    done
echo "****** SNPs location file extraction completed******"

# Extract SNP location file
echo "******SNP extraction started******"
for file in *.GT.FORMAT
    do
        tissue_name=`echo $file | sed -r 's/.{10}$//'`
        echo -e "snp\tchr\tpos" > "$tissue_name".snpsloc.txt
        awk 'NR > 1 {id=$1":"$2; print id"\tchr"$1"\t"$2}' $file \
        >> "$tissue_name".snpsloc.txt
    done

# Extract gene location data within 1mb genome region of the given gene_id
for file in *.v8.normalized_expression.bed
    do
        tissue_name=`echo $file | sed -r 's/.{29}$//'`
        awk -v OFS='\t' '{if($1~'/$chr_ID/' && $2>'$top' && $2<'$buttom' && $4 !~ '/$gene_ID/') \
        print $4, $1, $2, $3}' $file >> "$tissue_name".geneloc.txt
    done
echo "******extracting gene expression data completed******"

# Extract gene expression data within 1mb genome region of the given gene_id
for file in *.v8.normalized_expression.bed
    do
        tissue_name=`echo $file | sed -r 's/.{29}$//'`
        awk -v OFS='\t' '{if($1~'/$chr_ID/' && $2>'$top' && $2<'$buttom' \
        && $4 !~ '/$gene_ID/') print $0}' $file > "$tissue_name".temp
        cut -f1,2,3 --complement "$tissue_name".temp >> "$tissue_name".GE.txt
        rm -rf "$tissue_name".temp
    done
echo "extracting gene expression data completed"

# Format covariates file
for file in *.demographic.txt
    do
        tissue_name=`echo $file | sed -r 's/.{16}$//'`
        awk -v OFS='\t' 'BEGIN{print "subjet_id\tsex\tage\trace\t"} \
        {print $1, $2, $3, $4}' $file > "$tissue_name".cov.txt
        awk -v OFS='\t' '{print $1}' "$tissue_name".cov.txt | paste -s \
        > "$tissue_name".covariates.txt
        awk -v OFS='\t' '{print $2}' "$tissue_name".cov.txt | paste -s \
        >> "$tissue_name".covariates.txt
        awk -v OFS='\t' '{print $3}' "$tissue_name".cov.txt | paste -s \
        >> "$tissue_name".covariates.txt
        awk -v OFS='\t' '{print $4}' "$tissue_name".cov.txt | paste -s \
        >> "$tissue_name".covariates.txt
    done

# Organize output files and directories
echo "******organizing files and directories started******"
mkdir -p ../output
for file in *.GE.txt
    do
        tissue_name=`echo $file | sed -r 's/.{7}$//'`
        mkdir -p ../output/$tissue_name
        mv "$tissue_name".covariates.txt ../output/$tissue_name
        mv "$tissue_name".GE.txt ../output/$tissue_name
        mv "$tissue_name".snpsloc.txt ../output/$tissue_name
        mv "$tissue_name".SNP.txt ../output/$tissue_name
        mv "$tissue_name".geneloc.txt ../output/$tissue_name
    done
echo "******organizing files and directories completed******"

# Garbage removal
#rm -rf *.vcf *.txt *.FORMAT *.log *.nosex chr* 

echo "Job ended at:$(date --rfc-3339=seconds)"
