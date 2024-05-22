# Illumina pipeline
Marie Hannaert\
ILVO

Illumina pipeline is a pipeline to analyze short-reads from Illumina.
This repository is a snakemake workflow that can be used to analyze short-read data specific for . Everything needed can be found in this repository. I made this pipeline during my traineeship by ILVO-Plant. 

## Installing the Illumina pipeline
Snakemake is a workflow management system that helps to create and execute data processing pipelines. It requires Python 3 and can be most easily installed via the bioconda package.

### Installing Mamba
The first step to installing Mamba is installing Miniforge:
#### Unix-like platforms (Mac OS & Linux)
````
$ curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
$ bash Miniforge3-$(uname)-$(uname -m).sh
````
or 
````
$ wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
$ bash Miniforge3-$(uname)-$(uname -m).sh
````
If this worked the installation of Mamba is done, if this didn't work you can check the documentation of Miniforge with the following link:
[MiniForge](https://github.com/conda-forge/miniforge#mambaforge)
### Installing Bioconda 
Then perform a one-time set up of Bioconda with the following commands. This will modify your ~/.condarc file:
````
$ mamba config --add channels defaults
$ mamba config --add channels bioconda
$ mamba config --add channels conda-forge
$ mamba config --set channel_priority strict
````
When you followed these steps Bioconda normally is installed, when it still doesn't work you can check the documentation with the following link: [Bioconda](https://bioconda.github.io/)
### Installing Snakemake 
Now creating the Snakemake enviroment, we will do this by creating a snakemake mamba enviroment:
````
$ mamba create -c conda-forge -c bioconda -n snakemake snakemake
````
If this was succesfull you can now use the following commands for activation and for help: 
````
$ mamba activate snakemake
$ snakemake --help
````
To check the documentation of Snakemake you can use the following link: [Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)

Now the snakemake enviroment is ready for use with the pipeline. 

### Downloading the Illumina pipeline from Github
When you want to use the Illumina pipeline, you can download the complete pipeline, including: scripts, conda enviroments, ... on your own local maching. Good practise is to make a directory **Snakemake/** where you can collect all of your pipelines. Downloading the Illumina pipeline in your snakemake directory can be done by the following command: 
````
$ cd Snakemake/ 
$ git clone https://github.com/MarieHannaert/Illumina_Snakemake.git
````

## Executing the Illumina pipeline 
Before you can execute this pipeline you need to perform a couple of preparing steps. 
### Preparing
In the **Illumina_Snakemake/** you need to make the following directories: **data/samples**
````
$ cd Illumina_Snakemake/
$ mkdir data/samples
````
In the samples directory you need to palce the samples that you want to analyse. They must look like the following two samples:
- sample1_1.fq.gz
- sample1_2.fq.gz
- sample2_1.fq.gz
- sample2_2.fq.gz

If this is done there is one more important step left: 
#### Activation of Krona 
To install the local taxonomy database you must run the following commands: 
````
$ cd .snakemake/conda/cce02dcec3898e2025b146bc478991b8/opt/krona/updateTaxonomy.sh
$ bash updateTaxonomy.sh
````
Before you can do/find this you will probably first have to execute the snakemake one time. This is needed because then it will install the needed conda enviroments. So if you get an error don't panic, this is normal by the first execution. 

## Executing the Illumina pipeline
Now everything is ready to run the pipeline. 
If you want to run the pipeline without any output, just checking it it works, you can use the following command in the **Illumina_Snakemake/**: 
````
$ snakemake -np
````
Now you will get an overvieuw of all the steps in the pipeline. 

If you want to execute the pipeline and your samples are place in the **data/samples** directory, you can use the following command: 
````
$ snakemake -j 4
````
The -j option is needed when you work on a local server, this defines the number of treads that will be used to perform the pipeline, so you can chose the number yourself. 

When your done executing the pipeline you will find the following structure in you **Illumina_Snakemake/**:
````
Snakemake/
├─ Illumina_Snakemake/
|  ├─ .snakemake
│  ├─ data/
|  |  ├─sampels/
|  ├─ envs
|  ├─ scripts/
|  |  ├─beeswarm_vis_assemblies.R
|  |  ├─skani_quast_to_xlsx.py
|  ├─ Snakefile
│  ├─ results/
|  |  ├─00_fastqc/
|  |  ├─01_multiqc/
|  |  ├─02_fastqc/
|  |  ├─03_krona/
|  |  ├─04_fastp/
|  |  ├─05_shovill/
|  |  ├─06_skani/
|  |  ├─07_quast/
|  |  ├─08_busco/
|  |  ├─assemblies/
|  |  ├─busco_summary/
│  ├─ README
│  ├─ logs
````