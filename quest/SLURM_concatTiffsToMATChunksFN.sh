#!/bin/bash
#SBATCH -A p30771
#SBATCH -p normal
#SBATCH -t 01:00:00
#SBATCH -o ./logfiles/concatMatFile.%x-%j.out # STDOUT
#SBATCH --job-name="concatTiffsToMatFile"
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

module purge all

cd ~

#path to file 

INPUT_pathToTiffDirectory=$1
INPUT_outFile=$2

#load modules to use
module load matlab/r2023b

#cd to script directory
cd /home/jma819/CaliAli_quest
#run analysis 

matlab -nosplash -nodesktop -r "addpath(genpath('/home/jma819/CaliAli_quest'));inDir='$INPUT_pathToTiffDirectory';outFile='$INPUT_outFile';out=concat_tiffs_to_mat_chunksFN(inDir, outFile);disp(out);exit;"

echo 'finished concactenation'
