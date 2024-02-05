## scRNA-Seq pipeline workflow
## Performs SCENIC analysis


configfile: "configs/config.yaml"

#import os

#if os.path.exists('')


## outputs
def inputall(wildcards):
    if ( config['organism'] == 'human' ):
        databases = ["aertslab-pyscenic-0.10.0.sif",
                     "databases/motifs-v9-nr.hgnc-m0.001-o0.0.tbl",
                     "databases/hg38__refseq-r80__10kb_up_and_down_tss.mc9nr.feather",
                     "databases/hs_hgnc_curated_tfs.txt",
                     "output/aucell.csv"]
    if ( config['organism'] == 'mouse'):
        databases = ["aertslab-pyscenic-0.10.0.sif",
                     "databases/motifs-v9-nr.mgi-m0.001-o0.0.tbl",
                     "databases/mm10__refseq-r80__10kb_up_and_down_tss.mc9nr.feather",
                     "databases/mm_mgi_tfs.txt",
                     "output/aucell.csv"]
    return databases



## scRNA-Seq pipeline
rule all:
    input: inputall



## Installing singularity instance
rule install_pyscenic:
    output:
        "aertslab-pyscenic-0.10.0.sif"
    shell:
        "singularity build {output} docker://aertslab/pyscenic:0.10.0"


###############################################################################################

if ( config['organism'] == 'human' ):
    tbl_file='databases/motifs-v9-nr.hgnc-m0.001-o0.0.tbl'
if ( config['organism'] == 'mouse' ):
    tbl_file='databases/motifs-v9-nr.mgi-m0.001-o0.0.tbl'



## Download motifs
rule download_motifs:
    output:
        tbl_file
    run:
        if ( config['organism'] == 'human' ):
            shell("wget https://resources.aertslab.org/cistarget/motif2tf/motifs-v9-nr.hgnc-m0.001-o0.0.tbl \
                   -P databases")
        if ( config['organism'] == 'mouse' ):
            shell("wget https://resources.aertslab.org/cistarget/motif2tf/motifs-v9-nr.mgi-m0.001-o0.0.tbl \
                   -P databases")


##########################################################################################

if ( config['organism'] == 'human'):
    feather_file="databases/hg38__refseq-r80__10kb_up_and_down_tss.mc9nr.feather"
if ( config['organism'] == 'mouse'):
    feather_file="databases/mm10__refseq-r80__10kb_up_and_down_tss.mc9nr.feather"


## Download feather files
rule download_feather:
    output:
        feather_file
    run:
        if ( config['organism'] == 'human' ):
            shell("wget https://resources.aertslab.org/cistarget/databases/old/homo_sapiens/hg38/refseq_r80/mc9nr/gene_based/hg38__refseq-r80__10kb_up_and_down_tss.mc9nr.feather \
                   -P databases/")
        if ( config['organism'] == 'mouse' ):
            shell("wget https://resources.aertslab.org/cistarget/databases/old/mus_musculus/mm10/refseq_r80/mc9nr/gene_based/mm10__refseq-r80__10kb_up_and_down_tss.mc9nr.feather \
                   -P databases/")


####################################################################################

if ( config["organism"] == 'human' ):
    tf_file="databases/hs_hgnc_curated_tfs.txt"
if ( config["organism"] == 'mouse' ):
    tf_file="databases/mm_mgi_tfs.txt"


## Download TF list
rule download_TFlist:
    output:
        tf_file
    run:
        if ( config["organism"] == 'human' ):
            shell("wget https://raw.githubusercontent.com/aertslab/pySCENIC/master/resources/hs_hgnc_curated_tfs.txt \
                   -P databases/")
        if ( config["organism"] == 'mouse' ):
            shell("wget https://raw.githubusercontent.com/aertslab/pySCENIC/master/resources/mm_mgi_tfs.txt \
                   -P databases/")



## SCENIC 1st step: Boosting
rule network_inference:
    input:
        mtx = config["mtx"],
        tfs = tf_file,
        feather = feather_file,
        tbl = tbl_file,
        sif = "aertslab-pyscenic-0.10.0.sif"
    output:
        'output/adj.tsv'
    params:
        workers = config["workers"]
    shell:
        "singularity exec -B \
                     $PWD:$PWD  \
                     {input.sif} \
                     pyscenic grn --num_workers {params.workers} \
                     -o {output} \
                     --method grnboost2 \
                     {input.mtx} \
                     {input.tfs}"


##################################################################

## SCENIC 2nd step: Regulon construction
rule regulon_inference:
    input:
        mtx=config["mtx"],
        adj='output/adj.tsv'
    output:
        "output/reg.csv"
    params:
        feather=feather_file,
        tbl=tbl_file
    run:
        shell("singularity exec \
		    -B $PWD:$PWD aertslab-pyscenic-0.10.0.sif \
		    pyscenic ctx \
        	    {input.adj} \
                    {params.feather} \
                    --annotations_fname {params.tbl} \
                    --expression_mtx_fname {input.mtx} \
        	    --mode dask_multiprocessing \
        	    --output {output} \
        	    --num_workers 20 \
        	    --mask_dropouts")



####################################################################################

## SCENIC 3rd step: TF activity scoring of cells
rule aucell:
    input:
        mtx = config["mtx"],
        reg = 'output/reg.csv'
    output:
        'output/aucell.csv'
    run:
        shell("singularity exec \
		     -B $PWD:$PWD aertslab-pyscenic-0.10.0.sif \
		     pyscenic aucell \
		     {input.mtx} \
		     {input.reg} \
		     --output {output} \
	             --num_workers 20")
