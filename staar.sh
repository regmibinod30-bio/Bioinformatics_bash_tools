#!/bin/bash

# This script is written to convert vcf file to input file FAVOR(Functiona
# Annotation of Variants) annotation.The computation time for this script
# is really short. You dont need batch submission.


# Redirect stdout to log file
LOGFILE='favor_annotation.log'
echo "Redirecting logging information to $LOGFILE"
exec 3>&1 4>&2 1>$LOGFILE 2>&1

# Print script execution start time
echo "Job started at:$(date --rfc-3339=seconds)"

# Module load
module purge
module load bcftools/1.9
module list

# Directories and files
input='sorted.vcf.gz'
output='input_favor_sorted'

# Convert vcf to bcf file
bcftools view $input -Ob -o "$output".bcf
echo "file conversion completed"

# Extract the required columns
bcftools query -f '%CHROM %POS %REF %ALT\n' "$output".bcf > extracted_file
echo "columns extracted"

# Format rows in FAVOR format
awk '{print "chr"$1"-"$2"-"$3"-"$4}' extracted_file > "$output".txt

# Favor can take input file with maximum 10000 rows, split the file
head -10000 "$output".txt > 1_"$output".txt
head -20000 "$output".txt | tail -10000 > 2_"$output".txt
head -30000 "$output".txt | tail -10000 > 3_"$output".txt
head -40000 "$output".txt | tail -10000 > 4_"$output".txt
head -50000 "$output".txt | tail -10000 > 5_"$output".txt
head -60000 "$output".txt | tail -10000 > 6_"$output".txt
head -70000 "$output".txt | tail -10000 > 7_"$output".txt
head -80000 "$output".txt | tail -10000 > 8_"$output".txt
head -90000 "$output".txt | tail -10000 > 9_"$output".txt
head -100000 "$output".txt | tail -10000 > 10_"$output".txt
head -110000 "$output".txt | tail -10000 > 11_"$output".txt
head -120000 "$output".txt | tail -10000 > 12_"$output".txt
head -130000 "$output".txt | tail -10000 > 13_"$output".txt
head -140000 "$output".txt | tail -10000 > 14_"$output".txt
head -150000 "$output".txt | tail -10000 > 15_"$output".txt
head -160000 "$output".txt | tail -10000 > 16_"$output".txt
head -170000 "$output".txt | tail -10000 > 17_"$output".txt
head -180000 "$output".txt | tail -10000 > 18_"$output".txt
head -190000 "$output".txt | tail -10000 > 19_"$output".txt

# Organize the splitted files
mkdir -p favor_input
mv *"$output".txt favor_input/.


# Use loop above code can make this script shorter.

# Final cleanup
rm -rf "$output".bcf extracted_file

echo "Job completed at:$(date --rfc-3339=seconds)"


