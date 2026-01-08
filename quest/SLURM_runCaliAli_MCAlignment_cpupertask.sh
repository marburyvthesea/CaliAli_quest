#!/bin/bash
#SBATCH -A p30771
#SBATCH -p normal
#SBATCH -t 24:00:00
#SBATCH -o ./logfiles/CaliAli_dsMCAlignment.%x-%j.out # STDOUT
#SBATCH --job-name="CaliAli_mcAlignment_cpuspertask"
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=5200M

module purge all

cd ~

#path to file 

INPUT_pathToDSFiles=$1

echo $INPUT_pathToDSFiles

#add project directory to PATH
export PATH=$PATH/projects/p30771/


#load modules to use
module load gstreamer/1.20
module load matlab/r2023b

#cd to script directory
cd /home/jma819/CaliAli_quest
#run analysis 

matlab -nosplash -nodesktop -r "addpath(genpath('/home/jma819/CaliAli_quest')); \
n=str2double(getenv('SLURM_CPUS_PER_TASK')); \
if isnan(n) || n<1, n=str2double(getenv('SLURM_NPROCS')); end; \
if isnan(n) || n<1, n=feature('numcores'); end; \
maxNumCompThreads(n); \
dsPath='$INPUT_pathToDSFiles';run('runCaliAli_MCAlignment.m');exit;"

echo 'finished analysis'
