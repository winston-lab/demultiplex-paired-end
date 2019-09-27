
# 'demultiplex-paired-end' pipeline

## description

A pipeline which demultiplexes paired-end FASTQ files containing libraries with 5' 'inline' barcodes and A-tails (i.e. the barcodes are the first N bases read, followed by a 'T').

- demultiplexing is done using [fastq-multx](https://github.com/brwnj/fastq-multx), allowing one mismatch to the barcode (including A-tail) and searching read 1 only
- using [cutadapt](http://cutadapt.readthedocs.io/en/stable/guide.html), pairs of reads where both reads have the barcode are kept, and the barcodes (plus A-tails) are trimmed.
    - no 3' quality trimming is applied

## requirements

### required software

- Unix-like operating system (tested on CentOS 7.2.1511)
- Git
- [conda](https://conda.io/docs/user-guide/install/index.html)

### required files

- Multiplexed paired-end FASTQ files of libraries with 5' 'inline' barcodes and A-tails. This pipeline has only been tested with Illumina data.

## instructions

**0**. Clone this repository.

```bash
git clone https://github.com/winston-lab/demultiplex-paired-end.git
```

**1**. Create and activate the `demultiplex_paired_end` virtual environment for the pipeline using conda. The virtual environment creation can take a while.

```bash
# navigate into the pipeline directory
cd demultiplex-paired-end

# create the demultiplex_paired_end environment
conda env create -v -f envs/demultiplex_paired_end.yaml

# activate the environment
source activate demultiplex_paired_end

# to deactivate the environment
# source deactivate
```

**2**. Make a copy of the configuration file template `config_template.yaml` called `config.yaml`, and edit `config.yaml` to suit your needs.

```bash
# make a copy of the configuration template file
cp config_template.yaml config.yaml

# edit the configuration file
vim config.yaml    # or use your favorite editor
```

**3**. With the `demultiplex_paired_end` environment activated, do a dry run of the pipeline to see what files will be created.

```bash
snakemake -p --dry-run
```

**4**. If running the pipeline on a local machine, you can run the pipeline using the above command, omitting the `--dryrun` flag. You can also use N cores by specifying the `--cores N` flag. The first time the pipeline is run, conda will create separate virtual environments for some of the jobs to operate in. Running the pipeline on a local machine can take a long time, especially for many samples, so it's recommended to use an HPC cluster if possible. On the HMS O2 cluster, which uses the SLURM job scheduler, entering `sbatch slurm_submit.sh` will submit the pipeline as a single job which spawns individual subjobs as necessary. This can be adapted to other job schedulers and clusters by adapting `slurm_submit.sh`, which submits the pipeline to the cluster, `slurm_status.sh`, which handles detection of job status on the cluster, and `cluster.yaml`, which specifies the resource requests for each type of job.

