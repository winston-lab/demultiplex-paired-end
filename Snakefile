#!/usr/bin/env python

configfile: "config.yaml"

SAMPLES = config["samples"]
min_barcode_length = min([len(v) for k,v in SAMPLES.items()])

rule all:
    input:
        expand("fastq/{sample}.{read}.fastq.gz",
                sample=["unmatched"] + list(SAMPLES.keys()),
                read = ["r1", "r2"]),

# barcodes include the 'A' tail
rule make_barcode_file:
    output:
        "fastq/barcodes.fa"
    run:
        with open(output[0], "w") as out:
            for k,v in SAMPLES.items():
                out.write(f'>{k}\n^{v}T\n')

# demultiplex with cutadapt, trimming the barcode and the 'A' tail off the 5' end of each read
# barcode must be present in both reads of a pair
# error rate is set to allow for one mismatch to barcode
# no 3' quality trimming is applied
rule demultiplex:
    input:
        r1 = config["r1"],
        r2 = config["r2"],
        barcodes = "fastq/barcodes.fa"
    output:
        r1 = expand("fastq/{sample}.r1.fastq.gz", sample=["unmatched"] + list(SAMPLES.keys())),
        r2 = expand("fastq/{sample}.r2.fastq.gz", sample=["unmatched"] + list(SAMPLES.keys()))
    params:
        error_rate = 1/(min_barcode_length),
        overlap = min_barcode_length
    log:
        "logs/demultiplex.log"
    shell: """
        (cutadapt -g file:{input.barcodes} -G file:{input.barcodes} --error-rate={params.error_rate} --no-indels --overlap={params.overlap} --output=fastq/{{name}}.r1.fastq.gz --paired-output=fastq/{{name}}.r2.fastq.gz --untrimmed-output=fastq/unmatched.r1.fastq.gz --untrimmed-paired-output=fastq/unmatched.r2.fastq.gz {input.r1} {input.r2}) &> {log}
        """

