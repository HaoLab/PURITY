#!/usr/bin/bash 

PyClone=/home/songx/anaconda2/bin/PyClone

for i in `ls *P*/tsv/*.tsv` 
do 
path=`echo $i|awk -F '/' '{print $1}'`
sample=`echo $i|awk -F '/' '{print $3}'|awk -F '.' '{print $1}'`
yaml=$path/yaml
if [ ! -d "$yaml" ]; then
    mkdir $yaml
fi
##Prepare mutations input file(s) 
$PyClone build_mutations_file --in_file $i --out_file $path/yaml/$sample.yaml --prior total_copy_number
done
echo "ALL SAMPLE yaml is OK";

echo "STAR BUILDING A PYCLONE CONFIGURATION FILE";
##Building a PyClone configuration file
for j in `ls list/*table`
do
name=`echo $j|awk -F '/' '{print $2}'|awk -F '.' '{print $1}'`
echo "STAR $name";
cd $name
  plot=plot 
  table=table
  if [ ! -d "$plot" ]; then
    mkdir $plot
  fi
  if [ ! -d "$table" ]; then
    mkdir $table
  fi
  IFS_old=$IFS
  IFS=$' '
  for i in `ls tsv/*.tsv`
  do
    sample=`echo $i|awk -F '/' '{print $2}'|awk -F '.' '{print $1}'`
    IFS=$IFS_old
    $PyClone setup_analysis --in_file $i --working_dir $PWD/ --samples $sample --prior total_copy_number

##Run PyClone
    $PyClone run_analysis --config_file $PWD/config.yaml

##Plotting 
##posterior cellular prevalence densities
##To plot the posterior density of the cellular frequencies use
    $PyClone plot_loci --config_file $PWD/config.yaml --plot_file plot/loci_density --samples $sample --plot_type density
    $PyClone plot_loci --config_file $PWD/config.yaml --plot_file plot/loci_parallel_coordinates --samples $sample --plot_type parallel_coordinates
    $PyClone plot_loci --config_file $PWD/config.yaml --plot_file plot/loci_scatter --samples $sample --plot_type scatter
    $PyClone plot_loci --config_file $PWD/config.yaml --plot_file plot/loci_vaf_parallel_coordinates --samples $sample --plot_type vaf_parallel_coordinates
    $PyClone plot_loci --config_file $PWD/config.yaml --plot_file plot/loci_vaf_scatter --samples $sample --plot_type vaf_scatter
##Plotting the posterior similarity matrix 
##To output the posterior similarity matrix which shows how often mutations where sampled to be in the same cluster use
    $PyClone plot_loci --config_file $PWD/config.yaml --plot_file plot/loci_similarity --plot_type similarity_matrix --samples $sample
##Plotting multiple sample parallel coordinate plots
##To plot the mean cellular frequencies of mutations colour coded by cluster ID use 
    $PyClone plot_clusters --config_file $PWD/config.yaml --plot_file plot/cluster_parallel_coordinates --plot_type parallel_coordinates --samples $sample
    $PyClone plot_clusters --config_file $PWD/config.yaml --plot_file plot/cluster_density --plot_type density --samples $sample
    $PyClone plot_clusters --config_file $PWD/config.yaml --plot_file plot/cluster_scatter --plot_type scatter --samples $sample
##Build loci results table
##PyClone provides a method to output the mean cellular prevalence across each sample and the cluster id for each mutation. This can be used to generate various plots using your own code
    $PyClone build_table --config_file $PWD/config.yaml --out_file table/loci.txt --table_type loci --burnin 1000  --thin 10
    $PyClone build_table --config_file $PWD/config.yaml --out_file table/cluster.txt --table_type cluster --burnin 1000  --thin 10
    echo "$name is finished";
  done
cd ../
done
echo "ALL SAMPLE IS FINISHED";
