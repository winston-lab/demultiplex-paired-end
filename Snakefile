#!/usr/bin/env python

configfile: "config.yaml"

SAMPLES = config["samples"]

localrules: make_barcode_file

rule all:
    input:
        expand("fastq/{sample}.{read}.fastq.gz", sample=SAMPLES, read = ["r1", "r2"]),
        expand("fastq/nontrimmed/{sample}-nontrimmed.{read}.fastq.gz", sample=SAMPLES, read = ["r1", "r2"])

# barcodes include the 'A' tail
rule make_barcode_file:
    output:
        "fastq/barcodes.tsv"
    run:
        with open(output[0], "w") as out:
            for sample, barcode in SAMPLES.items():
                out.write(f'{sample}\t{barcode}T\n')

# demultiplex with fastq-multx (10x faster than cutadapt demultiplexing)
# allow one mismatch to barcode
# leave trimming of barcodes to cutadapt step to check for barcode on both reads
rule demultiplex:
    input:
        r1 = config["r1"],
        r2 = config["r2"],
        barcodes = "fastq/barcodes.tsv"
    output:
        r1 = expand("fastq/prefilter/{sample}-prefilter.r1.fastq.gz", sample=["unmatched"] + list(SAMPLES.keys())),
        r2 = expand("fastq/prefilter/{sample}-prefilter.r2.fastq.gz", sample=["unmatched"] + list(SAMPLES.keys()))
    log:
        "logs/demultiplex.log"
    shell: """
       (fastq-multx -B {input.barcodes} -b -x -m 1 {input.r1} {input.r2} -o fastq/prefilter/%-prefilter.r1.fastq.gz -o fastq/prefilter/%-prefilter.r2.fastq.gz) &> {log}
        """

# barcode must be present in both reads of a pair
# remove barcodes, including 'A' tail
# error rate is set to allow for one mismatch to barcode, disregarding 'A' tail
# no 3' quality trimming is applied
rule remove_barcodes:
    input:
        r1 = "fastq/prefilter/{sample}-prefilter.r1.fastq.gz",
        r2 = "fastq/prefilter/{sample}-prefilter.r2.fastq.gz"
    output:
        r1 = "fastq/{sample}.r1.fastq.gz",
        r2 = "fastq/{sample}.r2.fastq.gz"
    params:
        barcode = lambda wc: f"^{SAMPLES[wc.sample]}T",
        error_rate = lambda wc: 1/len(SAMPLES[wc.sample]),
        overlap = lambda wc: len(SAMPLES[wc.sample])+1
    threads: config["threads"]
    log:
        "logs/remove_barcodes/remove_barcodes_{sample}.log"
    shell: """
        (cutadapt --cores={threads} -g {params.barcode} -G {params.barcode} --error-rate={params.error_rate} --no-indels --overlap={params.overlap} --discard-untrimmed --output={output.r1} --paired-output={output.r2} {input.r1} {input.r2}) &> {log}
        """

# check for barcode in both reads of a pair, as above, but do not trim them
# these files are useful for GEO submission, which requires demultiplexed but unmodified fastq files
rule check_barcodes_only:
    input:
        r1 = "fastq/prefilter/{sample}-prefilter.r1.fastq.gz",
        r2 = "fastq/prefilter/{sample}-prefilter.r2.fastq.gz"
    output:
        r1 = "fastq/nontrimmed/{sample}-nontrimmed.r1.fastq.gz",
        r2 = "fastq/nontrimmed/{sample}-nontrimmed.r2.fastq.gz"
    params:
        barcode = lambda wc: f"^{SAMPLES[wc.sample]}T",
        error_rate = lambda wc: 1/len(SAMPLES[wc.sample]),
        overlap = lambda wc: len(SAMPLES[wc.sample])+1
    threads: config["threads"]
    log:
        "logs/remove_barcodes/remove_barcodes_{sample}.log"
    shell: """
        (cutadapt --cores={threads} -g {params.barcode} -G {params.barcode} --error-rate={params.error_rate} --no-indels --overlap={params.overlap} --no-trim --discard-untrimmed --output={output.r1} --paired-output={output.r2} {input.r1} {input.r2}) &> {log}
        """
