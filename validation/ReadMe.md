# Validation

This directory contains workflows and scripts used to validate that the **CWL** and [**WDL**](https://github.com/biowdl/RNA-seq/tree/develop) RNA-seq pipelines produce equivalent results. This validation compares both **intermediate outputs** and **generated count tables**, and performs **statistical checks** on the resulting data.

## Overview
Validation consists of three main stages:
1. Compare intermediate workflow outputs
2. Generate count tables from BAM files
3. Compare the generated count tables
4. Perform Pearson Correlation on intermediate outputs and generated count tables


## Directory Structure
```
validation/
├── .gitignore
├── ReadMe.md
├── align_to_count.cwl
├── align_to_count_inputs.yml
├── ct_compare.sh
├── file_difference.sh
├── tests.py
├── cwl_toil_env.txt
├── python_correlation_stats_env.txt
├── diff_summary.txt                    # gitignore
├── test_stats.tsv                      # gitignore
└── tmp/                                # gitignore
```

## Usage
```
bash file_difference.sh
```

```
cwltool --singularity align_to_count.cwl align_to_count_inputs.yml
```

```
bash ct_compare.sh
```

```
python tests.py
```

## Interpreting `NaN` values

It is possible for `NaN` values to occur in `test_stats.tsv`. This then indicates that the data of the respective column was the same. Meaning the Pearson Correlation, based on differences being of the same magnitude at the same point could not calculate any difference at all.
 
---
 
## Pipeline Performance (`sacct_toil_stats.py`)
 
After a pipeline run, SLURM job accounting data can be collected and summarised
using `sacct_toil_stats.py`. The output is comparable to `toil stats` and
covers total CPU time, overall runtime, and peak memory usage across all
completed Cromwell jobs.
 
### Collecting SLURM data
 
```bash
sacct -u $USER \
  -S <STARTDATE> \
  -E <ENDDATE> \
  --format=JobID,JobName,Submit,Start,End,State,AllocCPUS,ElapsedRaw,CPUTimeRAW,MaxRSS,ReqMem \
  --units=K \
  > sacct.txt
```
 
Replace `<STARTDATE>` and `<ENDDATE>` with the date range of your run,
e.g. `2025-09-14` and `2025-09-16`. `sacct.txt` is gitignored as it contains
cluster-specific job IDs.
 
### Running
 
```bash
python sacct_toil_stats.py
```
 
`INPUT_FILE` at the top of the script points to `sacct.txt` in the same
directory. Edit it if your file is elsewhere.
 
### Example output
 
```
Batch System: slurm
Default Cores: 1  Max Cores: 4
Jobs (COMPLETED): 42
 
Local CPU Time:   18340.00 core·s
Total Wall Time:  18340.00 s  (5h 05m 40s)
Overall Runtime:   2187.00 s  (36m 27s)
 
Wall time per job:
  min    = 2 s
  median = 187.0 s
  mean   = 436.7 s
  max    = 1803 s  (30m 03s)
 
MaxRSS per job  (42/42 jobs):
  min    = 968 KiB
  median = 312.4 MiB
  mean   = 489.1 MiB
  max    = 14.23 GiB
```
 
| Field           | Definition                                                                    |
|-----------------|-------------------------------------------------------------------------------|
| Local CPU Time  | Sum of `CPUTimeRAW` across all jobs — total core-seconds consumed             |
| Total Wall Time | Sum of each job's wall time — how long a sequential run would have taken      |
| Overall Runtime | `max(End) − min(Start)` — true elapsed time with jobs running in parallel     |
| MaxRSS          | Peak resident memory per job, read from the `.batch` SLURM sub-step          |
 
> **Overall Runtime vs Total Wall Time:** because Cromwell submits jobs in
> parallel, Overall Runtime is typically much shorter than Total Wall Time.
 
### Filtering
 
Only jobs whose main SLURM state is `COMPLETED` are included. `TIMEOUT`,
`FAILED`, `CANCELLED`, and other states are skipped entirely — these jobs are
expected to be retried by Cromwell and should not contribute to the resource
summary. Note that SLURM marks the `.batch` sub-step of a `TIMEOUT` job as
`COMPLETED`; the script guards against this by checking the parent job state
first.
 
