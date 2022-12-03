#!/bin/bash
# =====================================
# generate_expression_matrix.sh
# =====================================
# This super-short script is written to process HT-seq output files before they
# are implemented in the R script for generating gene expression matrix. It
# basically parses the file-name. 
# =====================================
# How to implement the script
# =====================================
# The sample name must start from letter 's'.
# Put this script in the same directory where bam dir holding HT-Seq output
# dir resides.
# It does not require a batch script. It can be implemented in terminal using
# following commnad:
#                               < ./generate_expression_matrix.sh >

# Work on sepearate directory
mkdir -p gene_count
cp -r bam/*.gene-count.txt gene_count/.
cd gene_count

# Write standard error to log file
LOGFILE='test_exp_count.log'
exec 3>&1 4>&2 1>$LOGFILE 2>&1

# Extract HT-seq metadata
for file in *.gene-count.txt
    do
        file_name=`echo $file | sed -r 's/.{15}$//'`
        grep -v '__' $file > "$file_name".txt
        awk -v OFS='\t' '{if($1~'/__/') print FILENAME, $1, $2}' $file \
        >> ht_seq_metadata
    done
rm -rf *.gene-count.txt

# Select a file from the top of the list
# Insert "NA" in the second column where gene_name is not available
# Extract gene_id and gene_name
# Extract additional file with gene_name and gene_id combined
cat $(ls *.txt | head -1) > count_matrix
awk -F"\t" -v OFS="\t" 'BEGIN {print "gene_id""\t""gene_name" } \
{if($2=="") {$2="NA"} {print $1, $2}}' count_matrix \
> col_I_II.tsv

# Extract count column from the all count files with file name as the column
# heading
for file in *.txt
    do
        file_name=`echo $file | sed -r 's/.{4}$//'`
        awk -F"\t" -v OFS="\t" '{print $3}' $file > $file_name
    done
rm -rf *.txt

for file in s*
    do
        awk -F"\t" -v OFS="\t" 'BEGIN{print ARGV[1]} {print $1}' $file \
        > "$file".tsv 
    done

# Concatenate .tsv files on rows and generate gene_expression_matrix
# Concatenate first and second column (id/name) into single column and generate
# second gene_expression matrix
paste *.tsv | column -s " " -t  > gene_expression_matrix.txt
rm -rf col_I_II.tsv
awk -F"\t" -v OFS="\t" 'BEGIN{print "gene_id"":""gene_name"} \
{if($2=="") {$2="NA"} {print $1":"$2}}' count_matrix > col_I_II_combined.tsv
rm -rf count_matrix
paste *.tsv | column -s " " -t  > gene_id_name_combined_gene_expression_matrix.txt

# Final clean up
mv gene_expression_matrix.txt gene_id_name_combined_gene_expression_matrix.txt ../
cd ..
#rm -rf gene_count
