#!/bin/bash
#SBATCH -A p30771
#SBATCH -p genhimem
#SBATCH -t 48:00:00
#SBATCH -o ./logfiles/CaliAli_dsMCAlignment.%x-%j.out # STDOUT
#SBATCH --job-name="CaliAli_Alignment_cpuspertask"
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=1400G


set -euo pipefail

module purge all

cd ~

#inputs
INPUT_combinedDir="${1:?ERROR: need <combinedDir> as arg1}"
BVsize="${2:-}"   # optional string, e.g. "[1.60, 1.75]"  or "1.60,1.75"
gSig="${3:-}"     # optional

echo "combinedDir: $INPUT_combinedDir"
echo "BVsize     : ${BVsize:-<default>}"
echo "gSig       : ${gSig:-<default>}"


#add project directory to PATH
export PATH=$PATH/projects/p30771/
export PATH=$PATH/projects/b1118/
export PATH=$PATH/scratch/jma819/

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
runCaliAli_AlignmentFN('${INPUT_combinedDir}','${BVsize}','${gSig}');exit;"

echo 'finished analysis'
