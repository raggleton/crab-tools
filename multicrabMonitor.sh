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
    echo "Run in the multicrab folder that has the dataset folders inside"
    echo ""
    echo "Options:"
    echo "  -h Show this help message"
    echo ""
    exit 1
}

########################
# Start of main script
########################

while getopts "hvf:" opt; do
  case "$opt" in
    h)
      show_help >&2
      ;;
    '?')
      show_help >&2
      ;;
  esac
done
shift $((OPTIND-1)) # Shift off the options and optional --.


# for f in $(ls -l | egrep '^d' | awk '{print $NF}')
# for f in $(ls -d */)
# do 
#   crabCheckStatus.sh -f $f
#   if [ $? -gt 0 ]
#   then
#     echo "Failure to execute crabCheckStatus -f $f correctly, exiting." >&2
#     exit 1  
#   fi
# done

# This produces a lovely summary at the end so you can see at a glance what's worked
ALL_DONE=1
# for f in $(ls -l | egrep '^d' | awk '{print $NF}')
for f in $(ls -d */)
do
	if [[ -n $(find . -name ${f%/}"_success.sh") ]]; then # Need to remove the trailing / on end of folders from ls -d
		echo $f " +++ DONE :D"
	else
		echo $f " --- STILL RUNNING :("
    ALL_DONE=$((ALL_DONE*0))
	fi
done

# If all done, make some scripts that allows you to get all, and also allow you to copy all data
if [ $ALL_DONE ]
then
  # If "do all" scripts exists already, delete them
  if [ -f getAll.sh ]
    then
    rm getAll.sh
  fi
  if [ -f copyAll.sh ]
    then
    rm getAll.sh
  fi

  echo "All done"
  echo "Making scripts to get and copy all data"
  for f in $(ls -d */)
  do
    echo "nohup crab -get all -c $f > ${f%/}_get.out&" >> getAll.sh
    echo "nohup crab -copyData -c $f > ${f%/}_copy.out&" >> copyAll.sh
  done
  chmod u+x getAll.sh
  chmod u+x copyAll.sh
  echo "Please run ./getAll.sh then ./copyAll.sh to get and copy all output"
fi
