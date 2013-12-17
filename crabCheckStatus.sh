#! /bin/bash

getResub(){
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

# STATUS=`crab -status -c $1`
# echo "$STATUS" #Need "" to make it multi-line, otherwise WILL FAIL

# Outputs all failed job numbers into array
# -v ind=1 is external variable that tracks the index of jobs array (internal awk array)
# The tee bit outputs to both stderr AND pipes it through to awk!!!
crab -status -c $1 # Have to run command normally first, then run again piping throgh tee. I don't know why - flush issue?
STATUS=$(crab -status -c $1 | tee /dev/stderr)
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
echo $1

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
			getResub $LIST $1
			LIST=""
		fi
		x=$((x+1))
	done
	# Left over job numbers
	LIST=${LIST#,}
	getResub $LIST $1

else
	if echo "$STATUS" | grep --quiet "Jobs Submitted\|Running\|Created"; then
		echo " -- JOBS STILL RUNNING/SUBMITTED"
	else
		# Need to add in a check that number of Total Jobs = number of Jobs Done
		TOTAL=$(echo "$STATUS" | awk '/Total Jobs/ { print $2}')
		DONE=$(echo "$STATUS" | awk -F: '/Jobs with Wrapper Exit Code : 0/ && $0 != "" { split($1,d," "); print d[2] }')
		if [ $TOTAL -eq $DONE ]; then
			# Need to add in a check that number of Total Jobs = number of Jobs Done
			echo " ++ CONGRATS, ALL DONE"
			echo "Outputting bash script to get jobs for this dataset"
			# Do some get all
			# Put in safety check here before getting all!
			if [ -f $1_success.sh ]; then
				echo "Deleting old $1_success.sh"
				rm $1_success.sh
			fi
			echo "Do ./$1_success.sh"
			echo '#!/bin/bash' > $1_success.sh
			echo "crab -get all -c" $1 >> $1_success.sh
			chmod u+x $1_success.sh
			# crab -get all -c $1 
		fi
	fi
fi
echo "***********************************************************"