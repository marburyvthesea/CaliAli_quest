#!/bin/bash
#SBATCH -A p30771
#SBATCH -p normal
#SBATCH -t 24:00:00
#SBATCH -o ./logfiles/CaliAli_dsMCAlignment.%x-%j.out # STDOUT
#SBATCH --job-name="placeCellAnalysis"
#SBATCH --mem-per-cpu=5200M
#SBATCH -N 1
#SBATCH -n 24

module purge all

cd ~

#path to file 

INPUT_pathToMotionCorrectedFile=$1

echo $INPUT_pathToMotionCorrectedFile

#add project directory to PATH
export PATH=$PATH/projects/p30771/


#load modules to use
module load matlab/r2023b

#cd to script directory
cd /home/jma819/EXTRACT-public
#run analysis 

matlab -nosplash -nodesktop -r "addpath(genpath('/home/jma819/EXTRACT-public'));addpath(genpath('/home/jma819/EXTRACT_analysis_JJM'));maxNumCompThreads(str2num(getenv('SLURM_NPROCS')));filePath='$INPUT_pathToMotionCorrectedFile';num_partitions='$INPUT_numPartitions';savePath='$INPUT_savePath';run('runEXTRACT_JJM_quest.m');exit;"

echo 'finished analysis'
