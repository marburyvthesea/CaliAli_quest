#!/bin/bash
#SBATCH -A p30771
#SBATCH -p genhimem
#SBATCH -t 48:00:00
#SBATCH -o ./logfiles/CaliAli_dsMCAlignment.%x-%j.out # STDOUT
#SBATCH --job-name="CaliAli_Alignment_cpuspertask"
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=400G

#sbatch SLURM_runCaliAli_Alignment_highmemFromTiffs1_5TB.sh \
#  /scratch/jma819/CaliAli_testData/m326_Yiwen/day001_04012025_13_54_32 \
#  /scratch/jma819/CaliAli_testData/m326_Yiwen/day002_04022025_15_27_34 \
#  "[1 1.95]" \
#  "2"

set -euo pipefail

module purge all

cd ~

#inputs
#inputs: last two are optional overrides
BVsize="${@: -2:1}"   # second-to-last
gSig="${@: -1}"       # last
dirs=("${@:1:$#-2}")  # everything except last two

echo "dirs: ${dirs[*]}"
echo "BVsize: ${BVsize}"
echo "gSig: ${gSig}"

# Build MATLAB cell array literal: {'dir1','dir2',...}
mat_dirs="{"
for d in "${dirs[@]}"; do
  mat_dirs="${mat_dirs}'${d}',"
done
mat_dirs="${mat_dirs%,}}"

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
runCaliAli_MCAlignmentFNfromTiffs($mat_dirs,'$BVsize','$gSig');exit;"

echo 'finished analysis'
