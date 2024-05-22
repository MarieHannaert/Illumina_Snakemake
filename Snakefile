import os

CONDITIONS = ["1", "2"]

# Define directories
REFDIR = os.getcwd()
print(REFDIR)
sample_dir = REFDIR+"/data/samples"

sample_names = []
sample_list = os.listdir(sample_dir)
for i in range(len(sample_list)):
    sample = sample_list[i]
    if sample.endswith("_1.fq.gz"):
        samples = sample.split("_1.fq")[0]
        sample_names.append(samples)
        print(sample_names)

rule all:
    input:
        "results/01_multiqc/multiqc_report.html",
        expand("results/03_krona/{names}_{con}_krona.html", names=sample_names, con = CONDITIONS),
        expand("results/04_fastp/{names}_fastp.html", names=sample_names),
        expand("results/04_fastp/{names}_fastp.json", names=sample_names),
        expand("results/05_shovill/{names}", names=sample_names),
        expand("results/assemblies/{names}.fna", names=sample_names),
        "results/06_skani/skani_results_file.txt",
        "results/07_quast/quast_summary_table.txt",
        "results/06_skani/skANI_Quast_output.xlsx",
        "results/07_quast/beeswarm_vis_assemblies.png",
        "results/busco_summary"

rule fastqc: 
    input:
        "data/samples/{names}_{con}.fq.gz"
    output:
        result = directory("results/00_fastqc/{names}_{con}_fastqc/")
    log:
        "logs/fastqc_{names}_{con}.log"
    params:
        extra="-t 32"
    shell:
        """
        fastqc {params.extra} {input} --extract -o results/00_fastqc/ 2>> {log}
        """

rule multiqc:
    input:
        expand("results/00_fastqc/{names}_{con}_fastqc/", names=sample_names, con = CONDITIONS)
    output:
        "results/01_multiqc/multiqc_report.html",
        result = directory("results/01_multiqc/")  
    log:
        "logs/multiqc.log"
    conda:
        "envs/multiqc.yaml"
    shell:
        """
        multiqc results/00_fastqc/ -o {output.result} 2>> {log}
        """

rule Kraken2:
    input:
        "data/samples/{names}_{con}.fq.gz"
    output:
        "results/02_kraken2/{names}_{con}_kraken2.report"
    params:
        threads=16
    log:
        "logs/Kraken2_{names}_{con}.log"
    shell:
        """
        kraken2 --gzip-compressed {input} --db /var/db/kraken2/Standard --report {output} --threads {params.threads} --quick --memory-mapping 2>> {log}
        """

rule Krona:
    input:
        "results/02_kraken2/{names}_{con}_kraken2.report"
    output:
        "results/03_krona/{names}_{con}_krona.html"
    params:
        extra="-t 5 -m 3"
    log:
        "logs/Krona_{names}_{con}.log"
    conda:
        "envs/krona.yaml"
    shell:
        """
        ktImportTaxonomy {params.extra} -o {output} {input} 2>> {log}
        """

rule Fastp:
    input:
        first = "data/samples/{names}_1.fq.gz",
        second = "data/samples/{names}_2.fq.gz"
    output:
        first = "results/04_fastp/{names}_1.fq.gz",
        second = "results/04_fastp/{names}_2.fq.gz",
        html = "results/04_fastp/{names}_fastp.html",
        json = "results/04_fastp/{names}_fastp.json"
    params:
        extra="-w 32"
    log:
        "logs/fastp_{names}.log"
    shell:
        """
        fastp {params.extra} -i {input.first} -I {input.second} -o {output.first} -O {output.second} -h {output.html} -j {output.json} --detect_adapter_for_pe 2>> {log}
        """

rule shovill:
    input:
        first = "results/04_fastp/{names}_1.fq.gz",
        second = "results/04_fastp/{names}_2.fq.gz"
    output: 
        "results/05_shovill/{names}/contigs.fa",
        result = directory("results/05_shovill/{names}/")
        
    params:
        extra = "--cpus 16 --ram 16 --minlen 500 --trim"
    log:
        "logs/shovill_{names}.log"
    conda:
        "envs/shovill.yaml"
    shell:
        """
        shovill --R1 {input.first} --R2 {input.second} {params.extra} -outdir {output.result} --force 2>> {log}
        """

rule contigs:
    input:
        contigs_fa = "results/05_shovill/{names}/contigs.fa"
    output:
        assembly_fna = "results/assemblies/{names}.fna"
    shell:
        """
        cp {input.contigs_fa} {output.assembly_fna}
        """

rule skani:
    input:
        expand("results/assemblies/{names}.fna", names=sample_names)
    output:
        result = "results/06_skani/skani_results_file.txt"
    params:
        extra = "-t 24 -n 1"
    log:
        "logs/skani.log"
    conda:
       "envs/skani.yaml"
    shell:
        """
        skani search {input} -d /home/genomics/bioinf_databases/skani/skani-gtdb-r214-sketch-v0.2 -o {output} {params.extra} 2>> {log}
        """

rule quast:
    input:
        "results/assemblies/{names}.fna"
    output:
        directory("results/07_quast/{names}/")
    log:
        "logs/quast_{names}.log"
    conda:
        "envs/quast.yaml"
    shell:
        """
        quast.py {input} -o {output} 2>> {log}
        """

rule summarytable:
    input:
        expand("results/07_quast/{names}", names = sample_names)
    output: 
        "results/07_quast/quast_summary_table.txt"
    shell:
        """
        touch {output}
        echo -e "Assembly\tcontigs (>= 0 bp)\tcontigs (>= 1000 bp)\tcontigs (>= 5000 bp)\tcontigs (>= 10000 bp)\tcontigs (>= 25000 bp)\tcontigs (>= 50000 bp)\tTotal length (>= 0 bp)\tTotal length (>= 1000 bp)\tTotal length (>= 5000 bp)\tTotal length (>= 10000 bp)\tTotal length (>= 25000 bp)\tTotal length (>= 50000 bp)\tcontigs\tLargest contig\tTotal length\tGC (%)\tN50\tN90\tauN\tL50\tL90\tN's per 100 kbp" >> {output}
        # Initialize a counter
        counter=1

        # Loop over all the transposed_report.tsv files and read them
        for file in $(find -type f -name "transposed_report.tsv"); do
            # Show progress
            echo "Processing file: $counter"

            # Add the content of each file to the summary table (excluding the header)
            tail -n +2 "$file" >> {output}

            # Increment the counter
            counter=$((counter+1))
        done
        """

rule xlsx:
    input:
        "results/07_quast/quast_summary_table.txt",
        "results/06_skani/skani_results_file.txt"
    output:
        "results/06_skani/skANI_Quast_output.xlsx"
    shell:
        """
          scripts/skani_quast_to_xlsx.py results/
          mv results/skANI_Quast_output.xlsx results/06_skani/
        """

rule beeswarm:
    input:
        "results/07_quast/quast_summary_table.txt"
    output:
        "results/07_quast/beeswarm_vis_assemblies.png"
    shell: 
        """
            scripts/beeswarm_vis_assemblies.R {input}
            mv beeswarm_vis_assemblies.png results/07_quast/
        """

rule busco:
    input: 
        "results/assemblies/{names}.fna"
    output:
        directory("results/08_busco/{names}")
    params:
        extra= "-m genome --auto-lineage-prok -c 32"
    log: 
        "logs/busco_{names}.log"
    conda:
        "envs/busco.yaml"
    shell:
        """
        busco -i {input} -o {output} {params.extra} 2>> {log}
        """

rule buscosummary:
    input:
        expand("results/08_busco/{names}", names=sample_names)
    output:
        directory("results/busco_summary")
    conda:
        "envs/busco.yaml"
    shell:
        """
        mkdir -p {output}
        cp -r {input}/short_summary.specific.*.txt {output}
        cd {output}
        for i in $(seq 1 15 $(ls -1 | wc -l)); do
            echo "Verwerking van bestanden $i tot $((i+14))"
            mkdir -p part_"$i-$((i+14))"
            find . -maxdepth 1 -type f | tail -n +$i | head -15 | while read file; do
                echo "Verwerking van bestand: $file"
                mv "$file" part_"$i-$((i+14))"
            done
            generate_plot.py -wd part_"$i-$((i+14))"
        done
        cd ../..
        rm -dr busco_downloads
        """