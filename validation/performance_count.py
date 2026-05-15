"""Calculate pipeline performance statistics from SLURM sacct output.

Reads a sacct output file and prints a summary comparable to ``toil stats``,
including total CPU time, overall runtime, wall time distribution, and peak
memory usage per job. Intended to be run after a Cromwell-on-SLURM pipeline
run to characterise resource usage.

Each Cromwell job produces three SLURM accounting lines:
- The main job line — holds state, CPU allocation, and elapsed time
- The ``.batch`` sub-step — holds MaxRSS (peak memory)
- The ``.extern`` sub-step — ignored

Generate the input file before running this script::

    sacct -u $USER \\
      -S <STARTDATE> -E <ENDDATE> \\
      --format=JobID,JobName,Submit,Start,End,State,AllocCPUS,ElapsedRaw,CPUTimeRAW,MaxRSS,ReqMem \\
      --units=K \\
      > sacct.txt

The script expects the default sacct header (column names + dashed separator)
as the first two lines of the file. If ``--noheader`` is used, change
``lines[2:]`` to ``lines[0:]`` in both passes.
"""

from datetime import datetime
import re
import statistics

INPUT_FILE = "sacct.txt"


def parse_time(t):
    """Parse an ISO 8601 datetime string as returned by sacct.

    Args:
        t (str): Datetime string in the format ``%Y-%m-%dT%H:%M:%S``.

    Returns:
        datetime: Parsed datetime object (naive, no timezone).
    """
    return datetime.strptime(t, "%Y-%m-%dT%H:%M:%S")


def parse_kb(s):
    """Parse a sacct memory string into KiB.

    sacct returns memory values as a number followed by an optional unit suffix
    (K, M, G, T, P). When ``--units=K`` is passed to sacct all values are
    already in KiB, but the suffix is still present and must be stripped.

    Args:
        s (str): Memory string, e.g. ``"968K"``, ``"1536M"``, ``"2G"``.

    Returns:
        float or None: Value in KiB, or None if the string cannot be parsed.
    """
    m = re.fullmatch(r"([\d.]+)([KMGTP]?)", s.strip(), re.I)
    if not m:
        return None
    val  = float(m.group(1))
    unit = m.group(2).upper()
    mult = {"": 1, "K": 1, "M": 1024, "G": 1024**2, "T": 1024**3}
    return val * mult.get(unit, 1)


def fmt_kb(kb):
    """Format a KiB value as a human-readable string.

    Args:
        kb (float): Value in KiB.

    Returns:
        str: Human-readable string, e.g. ``"533.6 MiB"`` or ``"14.23 GiB"``.
    """
    if kb >= 1024**2: return f"{kb/1024**2:.2f} GiB"
    if kb >= 1024:    return f"{kb/1024:.1f} MiB"
    return f"{kb:.0f} KiB"


def fmt_s(sec):
    """Format a duration in seconds as a human-readable string.

    Args:
        sec (int or float): Duration in seconds.

    Returns:
        str: Human-readable string, e.g. ``"1h 03m 27s"`` or ``"15m 03s"``.
    """
    sec = int(sec)
    h, r = divmod(sec, 3600)
    m, s = divmod(r, 60)
    if h: return f"{h}h {m:02d}m {s:02d}s"
    if m: return f"{m}m {s:02d}s"
    return f"{s}s"


def collect_completed_ids(lines):
    """Identify SLURM job IDs whose main job line is COMPLETED.

    Scans main job lines only (no ``.`` in JobID). Jobs with any other state
    (TIMEOUT, FAILED, CANCELLED, etc.) are excluded. This is necessary because
    SLURM marks the ``.batch`` sub-step of a TIMEOUT job as COMPLETED, so
    sub-step state alone cannot be used as a filter.

    Args:
        lines (list of str): All lines from the sacct output file.

    Returns:
        set of str: Job IDs whose main job state is COMPLETED.
    """
    completed_ids = set()
    for line in lines[2:]:
        parts = line.split()
        if len(parts) < 6:
            continue
        jobid, state = parts[0], parts[5]
        if "." not in jobid and state.startswith("COMPLETED"):
            completed_ids.add(jobid)
    return completed_ids


def collect_job_data(lines, completed_ids):
    """Extract timing and memory data from .batch sub-steps of COMPLETED jobs.

    MaxRSS is only populated by SLURM on the ``.batch`` sub-step line, not on
    the main job line. ElapsedRaw and CPUTimeRAW are read directly from their
    columns rather than recomputed from timestamps.

    Args:
        lines (list of str): All lines from the sacct output file.
        completed_ids (set of str): Job IDs accepted by ``collect_completed_ids``.

    Returns:
        list of dict: One dict per accepted job with keys:
            - ``start`` (datetime): Job start time.
            - ``end`` (datetime): Job end time.
            - ``elapsed`` (int): Wall time in seconds (ElapsedRaw).
            - ``cpu_time`` (int): Core-seconds used (CPUTimeRAW).
            - ``cpus`` (int): Allocated CPU cores.
            - ``maxrss_kb`` (float or None): Peak memory in KiB, or None if absent.
    """
    jobs = []
    for line in lines[2:]:
        parts = line.split()
        if len(parts) < 9:
            continue
        jobid, state = parts[0], parts[5]
        if ".ba" not in jobid:
            continue
        parent_id = jobid.split(".")[0]
        if parent_id not in completed_ids:
            continue
        try:
            start    = parse_time(parts[3])
            end      = parse_time(parts[4])
            cpus     = int(parts[6])
            elapsed  = int(parts[7])   # ElapsedRaw  — wall seconds
            cpu_time = int(parts[8])   # CPUTimeRAW  — core·seconds
        except Exception:
            continue
        maxrss_kb = parse_kb(parts[9]) if len(parts) > 9 else None
        jobs.append({
            "start":     start,
            "end":       end,
            "elapsed":   elapsed,
            "cpu_time":  cpu_time,
            "cpus":      cpus,
            "maxrss_kb": maxrss_kb,
        })
    return jobs


def print_stats(jobs):
    """Compute and print pipeline performance statistics to stdout.

    Prints a summary in the style of ``toil stats``, including totals and
    per-job distributions for wall time, CPU time, and peak memory.

    Args:
        jobs (list of dict): Output of ``collect_job_data``.

    Raises:
        ValueError: If ``jobs`` is empty.
    """
    if not jobs:
        raise ValueError("No valid jobs found after filtering.")

    overall_runtime = (max(j["end"]   for j in jobs) -
                       min(j["start"] for j in jobs)).total_seconds()
    total_cpu_time  = sum(j["cpu_time"] for j in jobs)
    total_wall      = sum(j["elapsed"]  for j in jobs)
    max_cores       = max(j["cpus"]     for j in jobs)

    elapsed_vals = [j["elapsed"]   for j in jobs]
    rss_vals     = [j["maxrss_kb"] for j in jobs if j["maxrss_kb"] is not None]

    print("Batch System: slurm")
    print(f"Default Cores: 1  Max Cores: {max_cores}")
    print(f"Jobs (COMPLETED): {len(jobs)}")
    print()
    print(f"Local CPU Time:   {total_cpu_time:.2f} core·s")
    print(f"Total Wall Time:  {total_wall:.2f} s  ({fmt_s(total_wall)})")
    print(f"Overall Runtime:  {overall_runtime:.2f} s  ({fmt_s(overall_runtime)})")
    print()
    print("Wall time per job:")
    print(f"  min    = {min(elapsed_vals)} s")
    print(f"  median = {statistics.median(elapsed_vals):.1f} s")
    print(f"  mean   = {statistics.mean(elapsed_vals):.1f} s")
    print(f"  max    = {max(elapsed_vals)} s  ({fmt_s(max(elapsed_vals))})")
    if rss_vals:
        print()
        print(f"MaxRSS per job  ({len(rss_vals)}/{len(jobs)} jobs):")
        print(f"  min    = {fmt_kb(min(rss_vals))}")
        print(f"  median = {fmt_kb(statistics.median(rss_vals))}")
        print(f"  mean   = {fmt_kb(statistics.mean(rss_vals))}")
        print(f"  max    = {fmt_kb(max(rss_vals))}")


def main():
    """Orchestrate reading, filtering, and reporting of SLURM job statistics.

    1. Reads all lines from ``INPUT_FILE``
    2. Identifies COMPLETED parent job IDs with ``collect_completed_ids``
    3. Collects per-job metrics from ``.batch`` sub-steps with ``collect_job_data``
    4. Prints the summary with ``print_stats``
    """
    with open(INPUT_FILE) as f:
        lines = f.readlines()
    completed_ids = collect_completed_ids(lines)
    jobs = collect_job_data(lines, completed_ids)
    print_stats(jobs)


if __name__ == "__main__":
    main()