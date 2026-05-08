#!/bin/bash
#SBATCH -A p30771
#SBATCH -p genhimem
#SBATCH -t 12:00:00
#SBATCH -o ./logfiles/CaliAli_dsMCAlignment.%x-%j.out # STDOUT
#SBATCH --job-name="CaliAli_Alignment_cpuspertask"
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=200G

set -euo pipefail

module purge all

cd ~

# Inputs
INPUT_combinedDir="${1:?ERROR: need <combinedDir> as arg1}"
BVsize="${2:-}"   # optional string, e.g. "[1.60, 1.75]" or "1.60,1.75"
gSig="${3:-}"     # optional positive scalar

echo "combinedDir: $INPUT_combinedDir"
echo "BVsize     : ${BVsize:-<default>}"
echo "gSig       : ${gSig:-<default>}"

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
combinedDir='${INPUT_combinedDir}'; \
BVsize_str='${BVsize}'; \
gSig_str='${gSig}'; \
run('runCaliAli_Alignment_onMotionCorrectedFilesOrDet.m');exit;"

echo 'finished analysis'
