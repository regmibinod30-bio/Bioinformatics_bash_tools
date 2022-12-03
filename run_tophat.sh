 
 for i in trimmed_fqgz/*1.fq.gz
 do
     j=${i/trimmed_fqgz\//}
	 echo module load tophat/2.1.2 bowtie/2-2.4.1 \; tophat -p -r 200 --mate-std-dev 100 --no-coverage-search -G /fdb/igenom 
es/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes.gtf -o tophat    /${j/_1.fq.gz/} /fdb/igenomes/Homo_sapiens/UCSC/hg19/Sequence/    Bowtie2Index/genome $i ${i//_1/_2}
done
