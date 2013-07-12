Fresh Import:
$ cd /path/to/my/repo
$ git remote add origin https://sholtz@bitbucket.org/sholtz/panels_experiments.git
$ git push -u origin --all   # to push changes for the first time

panels_experiment_utilities - This repo has all of the utilities to take protocols 
from panels_experiments and run them on panels.

There are two running functions: run_imaging_panels_protocol.m and 
run_panels_protocol.m that differ slightly.If you want to run a simple experiment,
the run_imaging_panels_protocol.m has less moving parts and is more easily modified.

The running functions take the full path to a folder that contains a few files 
described in the panels_experiment README.md file.
