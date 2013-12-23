#!/bin/bash

# Robin Aggleton 2013
# This script runs over all datasets to check status & resubmit any failed jobs
# using my crabCheckStatus.sh script
#
# Usage: multicrabMonitor.sh
# (run in the multicrab folder with all the dataset folders inside)

function show_help {
    echo ""
    echo "This script will do crabCheckStatus.sh on all datasets in a multicrab set of datasets."
    echo "It will output a summary at the end of what has completed and what is left to finish"
    echo ""
    echo "Usage: multicrabMonitor.sh"
    echo ""
    echo "Options:"
    echo "  -h Show this help message"
    echo ""
    exit 
}

########################
# Start of main script
########################

while getopts "hvf:" opt; do
  case "$opt" in
    h)
      show_help
      exit 0
      ;;
    '?')
      show_help >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1)) # Shift off the options and optional --.


for f in $(ls -l | egrep '^d' | awk '{print $NF}')
do 
	crabCheckStatus.sh $f
done

# This produces a lovely summary at the end so you can see at a glance what's worked
for f in $(ls -l | egrep '^d' | awk '{print $NF}')
do
	if [[ -n $(find . -name $f"_success.sh") ]]; then
		echo $f " +++ DONE :D"
	else
		echo $f " --- STILL RUNNING :("
	fi
done
