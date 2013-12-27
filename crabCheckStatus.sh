#!/bin/bash

# Robin Aggleton 2013
# Does:
#  - crab -status
#  - crab -resubmit on any failed, aborted jobs
#  - produces script (FOLDER_success.sh) if all DONE to allow user to do crab -get

function getResub {
	# Does crab -get and resubmit
	# args: $1 = dataset name, $2 = list of job numbers
	echo "crab -get $1 -c $2"
	OUTPUT_GET=$(crab -get $1 -c $2 | tee /dev/stderr)
	echo "crab -resubmit $1 -c $2"
	crab -resubmit $1 -c $2
	
	# Look for failed/corrupted output and forceResubmit them
	# corr_arr=($(cat sampleGet.log | grep "seems corrupted" | sed 's/[^0-9]//g'))
	corr_arr=($(echo "$OUTPUT_GET" | grep "seems corrupted" | sed 's/[^0-9]//g'))
	echo ${corr_arr[@]}
	LIST_CORR=""
	if [ ${#corr_arr[@]} -gt 0 ]; then
		for f in ${corr_arr[@]}
		do
			LIST_CORR="$LIST_CORR,$f"
		done
		LIST_CORR=${LIST_CORR#,} # Chop off starting comma
		echo "crab -forceResubmit $LIST_CORR -c $2"
		crab -forceResubmit $LIST_CORR -c $2
	fi
}


function show_help {
    echo ""
    echo "This script will do crab -status, resubmit any failed/aborted jobs."
    echo "If all jobs are done, it will produce a script, DATASET_success.sh,"
    echo "which the user can run to do crab -get all on the dataset."
    echo ""
    echo "Usage: crabCheckStatus.sh -f <dataset folder>"
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
  exit 1
fi

# Interpret and command line arguments
# OPTIND=1 # Reset is necessary if getopts was used previously in the script.  
# It is a good idea to make this local in a function.
while getopts "hvf:" opt; do
  case "$opt" in
    h)
      show_help >&2
      ;;
    v)  
      VERBOSE=true
      ;;
    f)
      JOB_FOLDER=${OPTARG%/} #removes trailing / for later on
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
  exit 1
fi

# STATUS=`crab -status -c $JOB_FOLDER`
# echo "$STATUS" #Need "" to make it multi-line, otherwise WILL FAIL

# Outputs all failed job numbers into array
# -v ind=1 is external variable that tracks the index of jobs array (internal awk array)
# The tee bit outputs to both stderr AND pipes it through to awk!!!
crab -status -c $JOB_FOLDER # Have to run command normally first, then run again piping throgh tee. I don't know why - flush issue?
STATUS=$(crab -status -c $JOB_FOLDER | tee /dev/stderr)
myarr=($( echo "$STATUS" | awk -v ind=1 -F: '/Jobs with Wrapper Exit Code : / && $0 != "" {
	
	split($1,z," ")
	# print " Number of jobs for exit code " $2 " = " z[2];
	
	if ($2 != 0){ #Do one exit code at a time
		getline;

		n=split($2,a,","); # Num of elements in job number list - NOT the same as the number of jobs
		
		ind2=ind; # For job array index, starting at the end of the last set of job numbers

		for (i=1;i<=n;i++) { # Loop through job number arrays - still contains stupid hypens though. Get rid of them
			# print a[i];
			
			if (match(a[i],"-")){
				len_b=split(a[i],b,"-");
				for(j=b[1];j<=b[2];j++){ 
					# add intermediate numbers to array
					jobs[ind]=j;
					ind++;
				}
			} else{
				# ok by itself, add to job array
				jobs[ind]=a[i];
				ind++;
			}
		}

		# Prints out job number for this failure code
		for(c=ind2;c<=ind;c++)
			print jobs[c];
	}
}' ))

# Don't need to sort array - can just loop throught the array until get to 500 indices, etc 
echo " LETS ANALYSE"
# Check to see if there are actually any jobs that need resubmitting!
N_JOBS=${#myarr[@]}
echo $N_JOBS
echo "***********************************************************"
echo $JOB_FOLDER

# First of all, deal with fail & resubmits,
# then check to see if any still Submitted/running
# then if all ok, output script to get all
if [[ "$N_JOBS" -gt 0 ]]; then  
	echo " -- YOU HAVE $N_JOBS JOBS TO RESUBMIT"

	# Submit in batches of 500
	# Prob should incorporate my crabSubmitLots.sh here...
	x=0
	LIST=""
	while [ "$x" -lt "$N_JOBS" ]
	do
		LIST="$LIST,${myarr[x]}"
		let "test=$((x+1)) % 500"
		if [ "$test" -eq 0 ]; then
			LIST=${LIST#,}
			getResub $LIST $JOB_FOLDER
			LIST=""
		fi
		x=$((x+1))
	done
	# Left over job numbers
	LIST=${LIST#,}
	getResub $LIST $JOB_FOLDER

else
	if echo "$STATUS" | grep --quiet "Jobs Submitted\|Running\|Created"; then
		echo " -- JOBS STILL RUNNING/SUBMITTED"
	else
		# Need to add in a check that number of Total Jobs = number of Jobs Done
		TOTAL=$(echo "$STATUS" | awk '/Total Jobs/ { print $2}')
		DONE=$(echo "$STATUS" | awk -F: '/Jobs with Wrapper Exit Code : 0/ && $0 != "" { split($JOB_FOLDER,d," "); print d[2] }')
		if [ $TOTAL -eq $DONE ]; then
			# Need to add in a check that number of Total Jobs = number of Jobs Done
			echo " ++ CONGRATS, ALL DONE"
			echo "Outputting bash script to get jobs for this dataset"
			# Do some get all
			# Put in safety check here before getting all!
			if [ -f $JOB_FOLDER_success.sh ]; then
				echo "Deleting old "$JOB_FOLDER"_success.sh"
				rm "$JOB_FOLDER"_success.sh
			fi
			echo "Do ./"$JOB_FOLDER"_success.sh"
			echo '#!/bin/bash' > "$JOB_FOLDER"_success.sh
			echo "crab -get all -c" $JOB_FOLDER >> "$JOB_FOLDER"_success.sh
			chmod u+x "$JOB_FOLDER"_success.sh
			# crab -get all -c $JOB_FOLDER 
		fi
	fi
fi
echo "***********************************************************"