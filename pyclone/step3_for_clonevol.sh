#!/usr/bin/bash

###clonevol input文件格式整理
for i in `ls list/*table`
do
name=`echo $i|awk -F '/' '{print $2}'|awk -F '.' '{print $1}'`
cd $name
echo "$name STAR....";
   for j in `ls tsv/*.tsv`
   do
	group=`less $j|sed '1d'|awk -F '\t' '{print $8}'|uniq`
        awk -F '\t' 'BEGIN{OFS="\t"}{if(ARGIND==1){a[$1]=$7;b[$1]=$2"\t"$3;c[$1]=$9;d[$1]=$2+$3}else{if($2==a[$1]){print $3,c[$1],"FALSE",$6*100,$4*100,b[$1],d[$1],$6*100}}}' $j table/loci.txt > table/$group.tsv
	sed -i "1i cluster\tgene\tis.driver\t$group.vaf\t$group.ccf\t$group.ref.count\t$group.var.count\t$group.depth\t$group" table/$group.tsv
   done

paste table/*.tsv |awk -F '\t' 'BEGIN{OFS="\t"}{print $1,$2,$3,$5/2,$14/2,$5,$14,$6,$7,$8,$15,$16,$17,$5/2,$14/2}' >table/forclonevol.txt
rm table/*tsv

###运行clonevol包
clone=clonevol
forclonevol=clonevol/forclonevol.txt

if [ ! -d "$clone" ]; then
    mkdir clonevol
fi

if [ ! -f "$forclonevol" ]; then
    ln -s $PWD/table/forclonevol.txt clonevol/
fi

cd clonevol
Rscript /lustre/rdi/user/songx/PURITY/clonevol/clonevol.R
echo "$name FINISHED....";
echo "#####";
cd ../../
done
