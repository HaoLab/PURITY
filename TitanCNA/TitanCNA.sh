#!/usr/bin/bash

mkdir -p prepare 

museq_class=/lustre/rdi/user/songx/tools/software/museq/classify.py
museqTOcount=/lustre/rdi/user/songx/tools/software/titan_workflow-master/components/convert_museq_vcf2counts/component_seed/transform_vcf_to_counts.py
ref=/lustre/rdi/user/songx/tools/genome/hg19/ucsc.hg19.fasta
model=/lustre/rdi/user/songx/tools/software/museq/models_anaconda/model_v4.1.2_anaconda_sk_0.13.1.npz
config=/lustre/rdi/user/songx/tools/software/museq/metadata.config
readCounter=/lustre/rdi/user/songx/tools/software/hmmcopy_utils/bin/readCounter
gc=/lustre/rdi/user/songx/tools/software/hmmcopy_utils/data/gc_hg19.wig
map=/lustre/rdi/user/songx/tools/software/hmmcopy_utils/data/map_hg19.wig
TitanCNA=/lustre/rdi/user/songx/tools/software/titan_workflow-master/components/calc_correctreads_wig/component_seed/correctReads.R
panel=/lustre/rdi/user/songx/tools/genome/regions/panel6.bed
titanCNA=/lustre/rdi/user/songx/tools/software/TitanCNA-master/scripts/R_scripts/titanCNA.R
libdir=/lustre/rdi/user/songx/tools/software/TitanCNA-master/
select=/lustre/rdi/user/songx/tools/software/TitanCNA-master/scripts/R_scripts/selectSolution.R

cat list|while read NID Normal TID Tumor; do
###prepare inputfile（hetFile 和 cnFile）
##HetFile
python $museq_class normal:$PWD/bamfile/$Normal"_"$NID.bam tumour:$PWD/bamfile/$Tumor"_"$TID.bam reference:$ref model:$model -c $config -o $PWD/prepare/$TID"_"Tumor_Normal.vcf
python $museqTOcount -i $PWD/prepare/$TID"_"Tumor_Normal.vcf -o $PWD/prepare/$TID"_"hetFile.txt
awk -F '\t' '{if($1 !~ /_/) print}' $PWD/prepare/$TID"_"hetFile.txt > $PWD/prepare/$TID"_"hetFile2.txt
rm $PWD/prepare/$TID"_"hetFile.txt
##cnFile
$readCounter $PWD/bamfile/$Normal"_"$NID.bam > $PWD/prepare/$NID"_"Normal.wig
$readCounter $PWD/bamfile/$Tumor"_"$TID.bam > $PWD/prepare/$TID"_"Tumor.wig
Rscript $TitanCNA $PWD/prepare/$TID"_"Tumor.wig $PWD/prepare/$NID"_"Normal.wig $gc $map $panel $PWD/prepare/$TID"_"cnFile.txt UCSC #(若为NCBI，则填NCBI，可选)

###run TitanCNA for each ploidy (2,3,4) and clusters (1 to numClusters).Running TitanCNA for multiple restarts and model selection titanCNA.R should be run with multiple restarts for different values of (a) Ploidy (2,3,4) and (b) Number of clonal clusters.The R script selectSolution.R will help select the optimal cluster from all these solutions;其中，--alphaK和--alphaKHigh 值WES为2500，WGS为10000;

numClusters=3 #(from 1 to 5，more than 5 may not produce accurate results)
numCores=4

echo "Maximum unmber of clusters :$numClusters";
for ploidy in $(seq 2 4)
do
  echo "Running TITAN for $TID clusters.";
  outDir=run_ploidy$ploidy
  mkdir -p $PWD/results/$outDir/plot
  for numClust in $(seq 1 $numClusters)
  do
    echo "Running for ploidy=$ploidy";
    Rscript $titanCNA --id $TID --hetFile $PWD/prepare/$TID"_"hetFile2.txt --cnFile $PWD/prepare/$TID"_"cnFile.txt --numCores $numCores --outDir $PWD/results/$outDir --numClusters $numClust --ploidy_0 $ploidy --normal_0 0.5 --estimateNormal map --alphaK 1000 --alphaKHigh 1000 --genomeStyle UCSC --libdir $libdir --outPlotDir results/$outDir/plot/
  done
  echo "Completed job for $numClust clusters."
done

##select optimal solution
##threshold:Proportion ploidyRun2 likelihood greater than than ploidyRun3/4 by at least this value. [Default 0.05]
Rscript $select --ploidyRun2=$PWD/results/run_ploidy2 --ploidyRun3=$PWD/results/run_ploidy3 --ploidyRun4=$PWD/results/run_ploidy4 --threshold=0.05 -o $PWD/results/$TID.optimalClusters.txt
done
