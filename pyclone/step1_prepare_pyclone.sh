#!/usr/bin/bash

###准备运行pyclone的tsv文件（需要snv结果和cnv结果，其中cnv结果为cnvkit结果命令为cnvkit.py call -v *.snv.vcf(varscan) -i TUMOR -n NORMAL；snv结果(varscan)需进行annovar注释，注释命令为:/work-a/app/annovar/table_annovar.pl --buildver hg19 --otherinfo -remove -protocol refGene,ljb2_pp2hdiv,ljb2_pp2hvar,exac03,clinvar_20160302,gnomad_exome  -operation g,f,f,f,f,f -nastring . -vcfinput $i /work-a/user/hanwb/annovar/humandb &）

cat list/*table |while read sample group; do

snv=snv/$group/$sample.hg19_multianno.txt
cnv=snv/$group/$sample.call.cns
name=`echo $sample|awk -F '_' '{print $1}'`
tsv=$name/tsv

if [ ! -d "$tsv" ]; then
    mkdir $tsv
fi

length=`less $cnv|awk -F '\t' '{print NF}'|uniq`

if [ $length == 12 ]; then
    bedtools intersect -a <(sed '1d' $cnv) -b <(sed '1d' $snv) -wb|awk -F '\t' -v var="$group" 'BEGIN{OFS="\t"}{split($NF,a,":");split(a[2],b,",");print $13,$14,$7,$8,$9,$19,b[1],b[2],var}'|awk -v var="$sample" -F '\t' 'BEGIN{OFS="\t"}{if($4 == "" && $5==""){print $1":"$2,$7,$8,"2","0",$3,var,$9,$6}else{print $1":"$2,$7,$8,"2",$4,$3,var,$9,$6}}' >$name/tsv/$sample.1.tsv
fi

if [ $length == 9 ]; then
    bedtools intersect -a <(sed '1d' $cnv) -b <(sed '1d' $snv) -wb|awk -F '\t' -v var2="$group" -v var1="$sample" 'BEGIN{OFS="\t"}{split($NF,a,":");split(a[2],b,",");print $10":"$11,b[1],b[2],"2","0",$6,var1,var2,$16}'>$name/tsv/$sample.1.tsv
fi
#awk -F '\t' '{if(ARGIND==1){a[$1]=$2;b[$1]=$7"\t"$(NF-1)}else{if(a[$1]>$2 && a[$1]<$3 || a[$1]==$2 || a[$1]==$3){print $1"\t"a[$1]"\t"$7"\t"$8"\t"$9"\t"b[$1]}}}' $snv $cnv |awk -F ':' '{print $1"\t"$2}'|awk -F ',' '{print $1"\t"$2}'|awk -v var1="$sample" -v var2="$group" -F '\t' 'BEGIN{OFS="\t"}{if($4 == "" && $5==""){print $1":"$2,$8,$9,"2","0",$3,var1,var2,$6}else{print $1":"$2,$8,$9,"2",$5,$4,var1,var2,$6}}' > $name/tsv/$sample.1.tsv
done

for i in `ls *P*/tsv/*.1.tsv`
do

sample=`echo $i|awk -F '/' '{print $3}'|awk -F '.' '{print $1}'`
number=`less $i|awk -F '\t' '{if($9 ~ /,/);split($9,a,",");print length(a)}'|sort -n -r|head -n 1`
name=`echo $i|awk -F '/' '{print $1}'`

less $i|awk -v num="$number" -F '\t' 'BEGIN{OFS="\t"}{if($9 ~ /,/);split($9,a,",");for(i=1;i<=num;i++)print $1,$2,$3,$4,$5,$6,$7,$8,a[i]}'|awk -F '\t' '{if(length($9) != 0) print}'|uniq> $name/tsv/$sample.tsv
sed -i '1i mutation_id\tref_counts\tvar_counts\tnormal_cn\tminor_cn\tmajor_cn\tsample\tgroup\tgene' $name/tsv/$sample.tsv
rm $name/tsv/$sample.1.tsv

done
