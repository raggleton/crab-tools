crab-tools
==========

Tools to help you using crab. Because no one should have to suffer using CRAB. o_O

Please file any bugs/feature requests! 

Note that usage of these tools is at your own risk, although they worked fine when I treid them.

Tools:

- crabSubmitLots.sh
- crabCheckStatus.sh
- multicrabMonitor.sh

###crabSubmitLots.sh

This submits a set of jobs for a dataset. Use this to submit datasets which have >500 jobs, as Remote GlideIn doesn't let you submit more than 500 at a time. 

###crabCheckStatus.sh

This nifty script does the following on a dataset:

- does `crab -status`
- figures out which files have failed or been aborted
- resubmits those jobs for you

This saves you having to do `crab -status`, sift through the output and then do `crab -resubmit`.

**Please note:** this is for those generic 60307/8,8020/1 errors that are solved by just resubmitting. Before running this blindly, have a look at the Task Monitor webpage or doing a `crab -status` manually to see if it something more serious that requires more attention - it's not a magic tool!

###multicrabMonitor.sh

This is crabCheckStatus.sh, but for lots of datasets (i.e. when using multicrab). This goes through each folder, does `crabCheckStatus.sh` on each, then at the end reports back to you which datasets are done or still running in a neat summary.


TODO:
- [ ] run `multicrabMonitor.sh` with cron, so you can submit, and elave it for a day or so.
- [ ] tidy up scripts
- [ ] maybe consolodate scripts?
