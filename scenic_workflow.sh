## Run scenic pipeline
output_dir='/media/ag-cherrmann/cramirez/scRNASeq_pipeline/output/'
data_dir='/media/ag-cherrmann/cramirez/scRNASeq_pipeline/data/'
project_dir='/media/ag-cherrmann/cramirez/scRNASeq_pipeline/'
ge.mtx='calu_sct_normalised_12000_mock'

## Run grn model
singularity exec \
	-B $project_dir:$project_dir $project_dir'aertslab-pyscenic-0.9.18.sif' \
	pyscenic grn --num_workers 10 \
	-o $output_dir$ge.mtx'adj.tsv' \
	--method grnboost2 \
	$data_dir$ge.mtx'.tsv' \
	$data_dir'hs_hgnc_tfs.txt'


## Prunning the inferred grn
singularity exec \
        -B $project_dir:$project_dir $project_dir'aertslab-pyscenic-0.9.18.sif' \
	pyscenic ctx \
	$output_dir$ge.mtx'adj.tsv' \
	$project_dir'data/hg38__refseq-r80__10kb_up_and_down_tss.mc9nr.feather' \
	--annotations_fname $project_dir'data/motifs-v9-nr.hgnc-m0.001-o0.0.tbl' \
	--expression_mtx_fname $data_dir$ge.mtx'.tsv' \
	--mode "dask_multiprocessing" \
	--output $output_dir$ge.mtx'.csv' \
	--num_workers 20 \
	--mask_dropouts


## Ranking cells
singularity exec \
         -B $project_dir:$project_dir $project_dir'aertslab-pyscenic-0.9.18.sif' \
	 pyscenic aucell \
	 $data_dir$ge.mtx'.tsv' \
	 $output_dir$ge.mtx'reg.csv' \
	 --output $output_dir$ge.mtx'aucell.csv' \
	 --num_workers 20
