#!/bin/bash

# Robin Aggleton 2013
# Allows CRAB to submit more than 500 jobs 

# Usage: crabSubmitLots.sh <JOB FOLDER>
# e.g. crabSubmitLots.sh SignalM125_POWHEG
# This script will then submit all jobs for that dataset, even if > 500


# OLD:
# Usage: crabSubmitLots.sh <OPT> <JOB FOLDER> <JOB NUMBERS>
# -R option for resubmission instead of submission, *BUT IS BROKEN*
# only job folder argument is mandatory

# To find out how many jobs there are
# look in <JOB>/share/arguments.xml
# Or see how many the user has specified

OPT=""
JOB_FOLDER=""
JOB_NUMBERS=""

if [ "$#" -eq "1" ]
then
    JOB_FOLDER=$1
fi 

if [ "$#" -eq "2" ]
then
    JOB_FOLDER=$1
    JOB_NUMBERS=$2
fi 
   
if [ "$#" -eq "3" ]
then
    OPT=$1
    JOB_FOLDER=$2
    JOB_NUMBERS=$3
fi

if [ -z "$JOB_NUMBERS" ]
then
    NJOBS=`grep "JobID=*" $1/share/arguments.xml | wc -l`
    echo "Total number of jobs to submit: " $NJOBS
    x=1

    while [ "$x" -le "$NJOBS" ]
    do
         crab -submit $x-$((x+499)) -c $JOB_FOLDER
        x=$((x+500))
    done 
else
    echo $JOB_NUMBERS
    NJOBS=`echo $JOB_NUMBERS | awk -F "," '{ for (i=1; i<NF; i++) printf $i"\n" ; print $NF }' | wc -w`
    echo "Total number of jobs to submit: " $NJOBS

    IFS="," # internal variable for Internal Field Separator, defaults to whitespace, I've set it to ',' here
    counter=0
    JOBLIST=""
    for v in $JOB_NUMBERS # Loop over user requested jobs
    do 
        if [ "$counter" -eq 500 ] # Every 500, do a submission
        then
            # echo `crab -submit $JOBLIST -c $JOB_FOLDER`
            if [ "$OPT" == "-R" ]; then
                crab -resubmit $JOBLIST -c $JOB_FOLDER
            else
                crab -submit $JOBLIST -c $JOB_FOLDER
            fi
            # echo $JOBLIST
            JOBLIST=""
            counter=0
        fi
        
        IFS=" "
        if [ "$counter" -eq 0 ]
        then
            JOBLIST="$v"
        else
            JOBLIST="$JOBLIST,$v"
        fi
        ((counter+=1))
    done
    # echo `crab -submit $JOBLIST -c $JOB_FOLDER`
    if [ "$OPT" == "-R" ]; then
        crab -resubmit $JOBLIST -c $JOB_FOLDER
    else
        echo "sub"
        crab -submit $JOBLIST -c $JOB_FOLDER
    fi
    # echo $JOBLIST
fi
