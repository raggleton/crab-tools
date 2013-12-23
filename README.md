crab-tools
==========

Tools to help you using crab. Because no one should have to suffer using CRAB. o_O

Please file any bugs/feature requests! These scripts assume you're using bash.

Note that usage of these tools is at your own risk, although they worked fine when I tried them.

##Installation

In a location of your choice do:

```
git clone https://github.com/raggleton/crab-tools.git
cd crab-tools
echo "export PATH=\$PATH:$(pwd)" >> ~/.bash_profile # Adds crab-tools folder to PATH variable
```

Now you can call any of my tools from any folder! Just type in the script name and any args to execute it. For help, use the `-h` arg.

##Tools:

- crabSubmitLots.sh
- crabCheckStatus.sh
- multicrabMonitor.sh

###crabSubmitLots.sh

This submits a set of jobs for a dataset. Use this to submit datasets which have >500 jobs, as Remote GlideIn doesn't let you submit more than 500 at a time. 

Usage: `crabSubmitLots.sh -f <FOLDER NAME>`

###crabCheckStatus.sh

This nifty script does the following on a dataset:

- does `crab -status`
- figures out which files have failed or been aborted
- resubmits those jobs for you

This saves you having to do `crab -status`, sift through the output and then do `crab -resubmit`.

If all jobs are DONE it will output a script file, `DATASETNAME_success.sh`, which you can run to do `crab -get all` on the dataset. This program purposely *doesn't* run this, in case all jobs are not done for some reason.

Usage: `crabCheckStatus.sh -f <FOLDER NAME>`

**Please note:** this is for those generic 60307/8,8020/1 errors that are solved by just resubmitting. Before running this blindly, have a look at the Task Monitor webpage or doing a `crab -status` manually to see if it something more serious that requires more attention - it's not a magic tool!

###multicrabMonitor.sh

This is crabCheckStatus.sh, but for lots of datasets (i.e. when using multicrab). This goes through each folder, does `crabCheckStatus.sh` on each, then at the end reports back to you which datasets are done or still running in a neat summary.


TODO:
- [ ] make more user friendly with "Usage:..." output
- [ ] run `multicrabMonitor.sh` with cron, so you can submit, and leave it for a day or so.
- [ ] tidy up scripts
- [ ] maybe consolodate scripts?
- [ ] improve checks by checking against actual files in Bristol T2