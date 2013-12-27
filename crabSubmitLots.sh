#!/bin/bash

# Robin Aggleton 2013
# Allows CRAB to submit more than 500 jobs for a given dataset folder
#
# Usage: crabSubmitLots.sh -f <JOB FOLDER>
# e.g. crabSubmitLots.sh -f SignalM125_POWHEG
# This script will then submit all jobs for that dataset, even if > 500

function show_help {
    echo ""
    echo "This script will submit all CRAB jobs for a specified dataset, even if > 500 jobs."
    echo ""
    echo "Usage: crabSubmitLots.sh -f <dataset folder>"
    echo ""
    echo "Options:"
    echo "  -f <folder> Specify dataset folder"
    echo "  -h Show this help message"
    echo "  -v Display verbose messages, for debugging only"
    echo ""
    exit 1
}

########################
# Start of main script
########################

JOB_FOLDER=""
VERBOSE=false

# Check to see if the user has passed an argument or not
if [ $# -eq 0 ]
then
  echo "Error: Program requires argument"
  show_help >&2
fi

# Interpret and command line arguments
# OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hvf:" opt; do
  case "$opt" in
    h)
      show_help >&2
      ;;
    v)  
      VERBOSE=true
      ;;
    f)
      JOB_FOLDER=$OPTARG
      ;;
    '?')
      show_help >&2
      ;;
  esac
done
shift $((OPTIND-1)) # Shift off the options and optional --.

if $VERBOSE
then
  echo "verbose=$VERBOSE, job_folder='$JOB_FOLDER', Leftovers: $@"
fi

# Check what other stuff the user has passed
if [ "$@" ]
then
  echo ""
  echo "I don't know what to do with this: $@"
  show_help >&2
fi

# Check if user specified a valid folder
if [ ! -d "$JOB_FOLDER" ]
then
  echo "Specified folder $JOB_FOLDER does not exist, please check again!" >&2
fi

# Find out how many jobs there are
# using the DATASET/share/arguments.xml file
NJOBS=`grep "JobID=*" $JOB_FOLDER/share/arguments.xml | wc -l`
echo "Total number of jobs to submit: " $NJOBS
job_lower=1
job_upper=1

# Loop over range of jobs in groups of 500
# and do crab -submit on them
while [ "$job_lower" -le "$NJOBS" ]
do
  if [ "$NJOBS" -lt $((job_lower+499)) ]
  then
    job_upper=$NJOBS
  else
    job_upper=$((job_lower+499))
  fi

  echo "crab -submit $job_lower-$job_upper -c $JOB_FOLDER"
  crab -submit $job_lower-$job_upper -c $JOB_FOLDER
  job_lower=$((job_upper+1))
done 

