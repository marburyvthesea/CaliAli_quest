#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
slurm_script="${script_dir}/SLURM_runCaliAli_dsMCAlignment.sh"
default_root="/scratch/jma819/CaliAli_linearTrackData"

usage() {
    cat <<'EOF'
Usage:
  submit_SLURM_runCaliAli_dsMCAlignment_by_subject.sh <subject_or_dir> <dsInput> <BVsize_str> <gSig_str> [session_subdir_or_gray_dir ...]

Examples:
  submit_SLURM_runCaliAli_dsMCAlignment_by_subject.sh 989 2 "[0.10 0.95]" "2.00"
  submit_SLURM_runCaliAli_dsMCAlignment_by_subject.sh /scratch/jma819/CaliAli_linearTrackData/989 2 "[0.10 0.95]" "2.00"
  submit_SLURM_runCaliAli_dsMCAlignment_by_subject.sh 989 2 "[0.10 0.95]" "2.00" \
    2025_01_01_989_15_29_53 2025_01_02_989_17_19_20

Behavior:
  - If <subject_or_dir> is a directory, it is used directly.
  - Otherwise it is resolved under /scratch/jma819/CaliAli_linearTrackData/<subject_or_dir>.
  - If no session arguments are provided, all */Denoised/gray directories under the subject directory are used.
  - If session arguments are provided, each can be either:
      * a session subdirectory name under the subject directory, or
      * a full path to a Denoised/gray directory.
EOF
}

if [ "$#" -lt 4 ]; then
    usage
    exit 1
fi

subject_input="$1"
dsInput="$2"
BVsize_str="$3"
gSig_str="$4"
shift 4

if [ -d "$subject_input" ]; then
    subject_dir="$subject_input"
else
    subject_dir="${default_root}/${subject_input}"
fi

if [ ! -d "$subject_dir" ]; then
    echo "Subject directory not found: $subject_dir" >&2
    exit 1
fi

if [ ! -f "$slurm_script" ]; then
    echo "SLURM wrapper not found: $slurm_script" >&2
    exit 1
fi

gray_dirs=()

if [ "$#" -gt 0 ]; then
    for session in "$@"; do
        if [ -d "$session" ]; then
            candidate="$session"
        elif [ -d "${subject_dir}/${session}/Denoised/gray" ]; then
            candidate="${subject_dir}/${session}/Denoised/gray"
        elif [ -d "${subject_dir}/${session}" ]; then
            candidate="${subject_dir}/${session}"
        else
            echo "Could not resolve session input: $session" >&2
            exit 1
        fi

        if [ ! -d "$candidate" ]; then
            echo "Resolved path is not a directory: $candidate" >&2
            exit 1
        fi

        case "$candidate" in
            */Denoised/gray) ;;
            *)
                echo "Session input must resolve to a Denoised/gray directory: $candidate" >&2
                exit 1
                ;;
        esac

        gray_dirs+=("$candidate")
    done
else
    mapfile -t gray_dirs < <(find "$subject_dir" -mindepth 3 -maxdepth 3 -type d -path '*/Denoised/gray' | sort)
fi

if [ "${#gray_dirs[@]}" -eq 0 ]; then
    echo "No Denoised/gray directories found under: $subject_dir" >&2
    exit 1
fi

echo "Subject directory: $subject_dir"
echo "Found ${#gray_dirs[@]} input directories:"
printf '  %s\n' "${gray_dirs[@]}"
echo "dsInput   : $dsInput"
echo "BVsize_str: $BVsize_str"
echo "gSig_str  : $gSig_str"

cmd=(sbatch "$slurm_script" "${gray_dirs[@]}" "$dsInput" "$BVsize_str" "$gSig_str")

echo "Submitting command:"
printf '  %q' "${cmd[@]}"
printf '\n'

"${cmd[@]}"
