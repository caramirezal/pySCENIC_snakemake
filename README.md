# pySCENIC Snakemake pipeline

Snakemake pipeline implementing pySCENIC workfow to be used 
in the Curry BioQuant cluster. At this stage is intented to 
start from counts or normalised gene expression matrices of
already mapped reads so this pipeline provides tools for data
analysis of gene expression data.

## Integrated modules

At the present the following modules are included:

* pySCENIC - Algorithm to infere regulons for Transcription
Factors and scoring cells according to the expression of genes
in this modules.


## Structure of the pipeline directory

```
root -- databases 
     -- sc
     -- input
     -- output
     -- configs    
```

## 1. Installation 

 * Clone the github repository:

```
git clone https://github.com/hdsu-bioquant/pySCENIC_pipeline.git
```

 * Create and activate a conda environment with snakemake (version >= 5.31.1).


## 2. Options configuration

In this step you must provide the local paths to where your 
specific data is located.

### Definition of the pySCENIC input 

In order to run the pySCENIC module you need to provide
a normalised gene expression matrix. Please, store the file
containing the matrix in the ```input/``` directory. 

Edit the ```config/config.yaml``` file as follows:

```
mtx: input/my_matrix_file_name.tsv
organism: human
workers: 10
```

 * mtx - The path to the gene expression matrix input (my_matrix_file_name.tsv,
for example).
 * organism - Can be set to 'human' or 'mouse'.
 * workers - Number of workers for GRNBoost step. Note: For very small datasets
sometimes this parameter must be set to a low value (1~3) otherwise an error 
might rise.


**IMPORTANT**: The matrix input used by pySCENIC must be
a tsv file with genes in columns and cells in rows (as 
opposed to the majority of scRNA-Seq tools). Please, check
the pySCENIC [documentation](!https://pyscenic.readthedocs.io/en/latest/installation.html) 
for more details.  

## 2. Running the pipeline

Go to the root directory of the snakemake pipeline and
execute the simple command:

```
snakemake --cores 20 --configfile configs/config.yaml
```

##  3. Inspection of the results

Once the pipeline is finished the results are going to be stored in the 
```output``` directory. For more information about the 
pySCENIC output we referred to the corresponding 
[documentation](!https://pyscenic.readthedocs.io/en/latest/installation.html).

**NOTE**: Because of the differences in machine platform and cluster settings
it is advisable to test first the pipeline using the example matrix 
colon_scenic_input_test_1k.tsv allready included in the input folder.
