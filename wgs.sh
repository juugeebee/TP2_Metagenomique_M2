#!/bin/bash
chmod +x wgs.sh

folderin=$1
folderout=$2
mkdir $2

#### Identifier et quantifier les bactéries présentes dans un échantillon
mkdir $2/bowtie2

./soft/bowtie2-build databases/all_genome.fasta $2/bowtie2/all_genome

./soft/bowtie2 -x $2/bowtie2/all_genome -1 $1/EchG_R1.fastq.gz -2 $1/EchG_R2.fastq.gz --end-to-end --fast -S $2/bowtie2/echG.sam


#### Quantifier l’abondance de chaque bactérie en analysant le fichier sam

	## Convertir votre fichier sam en bam
mkdir $2/samtools
./soft/samtools-1.6/samtools view -S -b $2/bowtie2/echG.sam > $2/samtools/echG.bam

	## Trier votre bam
./soft/samtools-1.6/samtools sort $2/samtools/echG.bam > $2/samtools/echG_sorted.bam

	## Indexer le fichier bam
./soft/samtools-1.6/samtools index $2/samtools/echG_sorted.bam

	## Extraction du comptage
./soft/samtools-1.6/samtools idxstats $2/samtools/echG_sorted.bam

	## Association gi -> annotation
grep ">" databases/all_genome.fasta|cut -f 2 -d ">" >association.tsv


#### Assembler le génome des bactéries présentes
./soft/megahit -1 $1/EchG_R1.fastq.gz -2 $1/EchG_R2.fastq.gz --k-list 21 --mem-flag 0 -o $2/megahit


#### Prédire les gènes présents sur vos contigs
mkdir $2/prodigal
./soft/prodigal -i $2/megahit/final.contigs.fa -d $2/prodigal/prodigal.out.fna


#### Sélectionner les gènes “complets”
sed "s:>:*\n>:g" $2/prodigal/prodigal.out.fna | sed -n "/partial=00/,/*/p"|grep -v "*" > $2/prodigal/prodigal_out_full.fna


#### Annoter les gènes “complets” contre la banque resfinder
mkdir $2/blastn
./soft/blastn -query $2/prodigal/prodigal_out_full.fna -db databases/resfinder.fna -outfmt '6 qseqid sseqid pident qcovs evalue' -out $2/blastn/blast.out -evalue 0.001 -qcov_hsp_perc 80 -perc_identity 80 -best_hit_score_edge 0.001



	







