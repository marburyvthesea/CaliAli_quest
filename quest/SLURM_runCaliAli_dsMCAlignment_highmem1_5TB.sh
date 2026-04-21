#!/bin/bash
#SBATCH -A p30771
#SBATCH -p genhimem
#SBATCH -t 48:00:00
#SBATCH -o ./logfiles/CaliAli_dsMCAlignment.%x-%j.out
#SBATCH --job-name="CaliAli_mcAlignment_cpuspertask"
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=400G

set -euo pipefail

module purge all
cd ~

# Expect: dirs... dsInput BVsize_str gSig_str
# Optional behavior: pass "" "" for BVsize/gSig to mean "use defaults"
if [ "$#" -lt 4 ]; then
  echo "Usage:"
  echo "  sbatch $0 <dir1> [dir2 ...] <dsInput> <BVsize_str> <gSig_str>"
  echo ""
  echo "Examples:"
  echo "  sbatch $0 /path/day1 /path/day2 2 \"[1.6, 1.95]\" \"2\""
  echo "  sbatch $0 /path/day1 /path/day2 1 \"\" \"\""
  exit 1
fi

gSig_str="${@: -1}"
BVsize_str="${@: -2:1}"
dsInput="${@: -3:1}"
dirs=("${@:1:$#-3}")   # everything except last 3

echo "dsInput   : $dsInput"
echo "BVsize_str: ${BVsize_str:-<empty>}"
echo "gSig_str  : ${gSig_str:-<empty>}"
echo "dirs      : ${dirs[*]}"

# Build MATLAB cell array literal: {'dir1','dir2',...}
mat_dirs="{"
for d in "${dirs[@]}"; do
  mat_dirs="${mat_dirs}'${d}',"
done
mat_dirs="${mat_dirs%,}}"

module load gstreamer/1.20
module load matlab/r2023b

cd /home/jma819/CaliAli_quest

matlab -nosplash -nodesktop -r "addpath(genpath('/home/jma819/CaliAli_quest')); \
n=str2double(getenv('SLURM_CPUS_PER_TASK')); \
if isnan(n) || n<1, n=str2double(getenv('SLURM_NPROCS')); end; \
if isnan(n) || n<1, n=feature('numcores'); end; \
maxNumCompThreads(n); \
multiTiffInput = ${mat_dirs}; \
dsVal = str2double('${dsInput}'); \
BVsize_str = '${BVsize_str}'; \
gSig_str = '${gSig_str}'; \
runCaliAli_dsMCAlignmentFNfromTiffsorMat(multiTiffInput, dsVal, BVsize_str, gSig_str); \
exit;"
