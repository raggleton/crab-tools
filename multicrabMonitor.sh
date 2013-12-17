#!/bin/bash

# This runs over all datasets to check status & resubmit any failed jobs
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
