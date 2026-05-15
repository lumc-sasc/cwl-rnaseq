import numpy as np
import pandas as pd
from pathlib import Path
from os.path import join as pathjoin
from scipy.stats import pearsonr
from io import StringIO
from zipfile import ZipFile

def retrieval(filename):
    """
    Read and parse the pipeline input YAML file (`inputs.yml`) to extract data paths, cutadapt status, and number of reads.

    The input YAML provides:
    - 'groundTruth' and 'comparative': base directories for the two pipelines
    - 'expression', 'fpg', 'samples', 'samplesheet', 'lib-rg', 'full_countTable'
    - 'cut_adapt': boolean
    - 'reads': int (1 or 2)

    Args:
        filename (str): Path to the input YAML file.

    Returns:
        tuple:
            dict: Keys are pipeline components (groundTruth, comparative, etc.) with string values of relative paths or names.
            bool: True if cutadapt was run, False otherwise.
            int: Number of reads (1 or 2).
    """
    dataSource = {}
    with open(filename, "r") as inYml:
        inputData = inYml.readlines()
        for item in inputData:
            temp = item.strip().split(": ")
            if 'cut_adapt' not in temp[0] and 'reads' not in temp[0]:
                dataSource[temp[0].strip("\"'")] = temp[1].strip("\"'").rstrip("\\/")
            elif 'reads' in temp[0]:
                reads = int(temp[1].strip("\"'").rstrip("\\/"))
            elif "true" in temp[1].strip("\"'").rstrip("\\/").lower():
                cutadapt = True
            else:
                cutadapt = False
    return dataSource, cutadapt, reads


def pathing(dataSource):
    """
    Assemble full directory paths to all necessary files and verify that ground truth and comparative sample folders match.

    The function combines `dataSource` components to build:
    - pathList["GT_samples"] and pathList["CMP_samples"]: directories containing sample folders
    - pathList["GT_fpg_expression"] and pathList["CMP_fpg_expression"]: fragment-per-gene count tables
    - pathList["sampleID"]: full paths to each sample in both pipelines for downstream analysis
    - pathList["sampleID_lib-rg"]: full paths including library/read group subfolders

    Args:
        dataSource (dict): Output of `retrieval()`, contains base directories and other pipeline components.

    Raises:
        ValueError: If the sample folder names between ground truth and comparative pipelines do not match.

    Returns:
        tuple:
            dict: All joined paths needed for downstream functions.
            list: Sorted list of sample IDs (folder names) found in the GT pipeline.
    """
    pathList = {}
    pathList["GT_samples"] = pathjoin(
        dataSource["groundTruth"], dataSource["samples"]
    )  # SampleIDs
    pathList["CMP_samples"] = pathjoin(
        dataSource["comparative"], dataSource["samples"]
    )  # SampleIDs
    pathList["GT_fpg_expression"] = pathjoin(
        dataSource["groundTruth"], dataSource["expression"], dataSource["fpg"]
    )  # CountTables
    pathList["CMP_fpg_expression"] = pathjoin(
        dataSource["comparative"], dataSource["expression"], dataSource["fpg"]
    )  # CountTables

    GT_sampleIDs = sorted([f.name for f in Path(pathList["GT_samples"]).iterdir()])
    CMP_sampleIDs = sorted([f.name for f in Path(pathList["CMP_samples"]).iterdir()])

    if GT_sampleIDs != CMP_sampleIDs:
        raise ValueError("Sample IDs do not match!")
    else:
        print("Samples Match")
        pathList["sampleID"] = []
        pathList["sampleID_lib-rg"] = []
        for sampleID in GT_sampleIDs:
            pathList["sampleID"].append(
                pathjoin(pathList["GT_samples"], sampleID)
            )  # Markdups (Norm + UMI)
            pathList["sampleID"].append(
                pathjoin(pathList["CMP_samples"], sampleID)
            )  # Markdups (Norm + UMI)
            pathList["sampleID_lib-rg"].append(
                pathjoin(pathList["GT_samples"], sampleID, dataSource["lib-rg"])
            )  # FastQC, CutAdapt & Align
            pathList["sampleID_lib-rg"].append(
                pathjoin(pathList["CMP_samples"], sampleID, dataSource["lib-rg"])
            )  # FastQC, CutAdapt & Align
    return pathList, GT_sampleIDs


def MeasuredFastQC(pathList, sampleIDs, outfile_name, rdat):
    """
    Compute Pearson correlations for per-base sequence quality from FastQC reports for each sample and write them to an output file.

    - Reads are processed according to `rdat`:
    - `rdat[0]` is the cutadapt boolean
    - `rdat[1]` is number of reads
    - Uses `FastQCSetReader` to parse each set of FastQC zip reports
    - Uses `FastQCMath` to compute correlations
    - Appends results to `outfile_name`

    Args:
        pathList (dict): Paths to all directories, including sample subfolders with library/read group.
        sampleIDs (list): List of sample ID strings corresponding to sample folder names.
        outfile_name (str): Path to the output TSV file where results are written.
        rdat (list): `[cutadapt (bool), reads (int)]` controlling number of FastQC files to process per sample.
    """
    n_rep = 2 * rdat[1]
    if rdat[0]:
        n_rep = 4 * rdat[1]
    print("Starting FastQC stats")
    reports = []
    data = {}
    for entry in pathList["sampleID_lib-rg"]:
        reports.extend(
            sorted(
                [
                    pathjoin(entry, f.name)
                    for f in Path(entry).iterdir()
                    if f.name.endswith("_fastqc.zip")
                ]
            )
        )
    count = 0
    for i in range(0,len(reports),n_rep):
        module_data = FastQCSetReader(reports[i:i+n_rep])
        sampleID, pvals = FastQCMath(module_data, sampleIDs[count], reports[i:i+n_rep])
        data[sampleID] = pvals
        count += 1
    with open(outfile_name, "r") as infile:
        lines = infile.readlines()
    with open(outfile_name, "w") as setfile:
        if rdat[1]:
            setfile.write(
                lines[0].strip()
                + "\tR1_pearson_r\tR1_pearson_p\tR2_pearson_r\tR2_pearson_p\tcutadapt_R1_pearson_r\tcutadapt_R1_pearson_p\tcutadapt_R2_pearson_r\tcutadapt_R2_pearson_p\n"
            )
        else:
            setfile.write(
            lines[0].strip()
            + "\tR1_pearson_r\tR1_pearson_p\tR2_pearson_r\tR2_pearson_p\n"
        )
    with open(outfile_name, "a") as file:
        linecount = 0
        for line in lines[1:]:
            linecount += 1
            file.write(lines[linecount].strip() +"\t" + "\t".join(pvals) + "\n")
    print("Stopping FastQC stats")


def FastQCSetReader(fastqcs_set):
    """
    Parse a set of FastQC zip report files and extract the 'Per base sequence quality' module as numerical arrays.

    - Each zip file is expected to have a `fastqc_data.txt` file
    - Extracts only the 'Per base sequence quality' module for each report

    Args:
        fastqcs_set (list of str): Paths to FastQC zip files.

    Returns:
        dict: Mapping each zip file path to a 2D list of floats representing per-base quality scores.
    """
    module_data = {}
    for report in fastqcs_set:
        module_data[report] = {}
        inside_module = False
        with ZipFile(report) as z:
            with z.open(f"{report.split('/')[-1].strip('.zip')}/fastqc_data.txt") as file:
                lines = [line.decode('utf-8').strip() for line in file.readlines()]
        for line in lines:
            if line.startswith(">>Per base sequence quality"):
                inside_module = True
                data_rows = []
                continue
            if line.startswith("#"):
                continue
            if inside_module and not line.startswith("#") and not line.startswith(">>END_MODULE"):
                values = line.split()
                numbers = [float(x) for x in values[1:]]
                data_rows.append(numbers)
            if line.startswith(">>END_MODULE") and inside_module:
                inside_module = False
                module_data[report]["Per base sequence quality"] = data_rows
    return module_data


def FastQCMath(module_data, sampleID, reports):
    """
    Compute Pearson correlation coefficients between pairs of FastQC reports for a single sample.

    - Assumes the input `module_data` contains parsed per-base sequence quality arrays
    - Flattens arrays and computes correlations between original and cutadapt-processed reads if applicable

    Args:
        module_data (dict): Output from `FastQCSetReader`, per-report numerical arrays.
        sampleID (str): Sample folder name for this set of reports.
        reports (list of str): Ordered list of report paths corresponding to this sample.

    Returns:
        tuple:
            str: Sample ID.
            list of str: Flattened list of Pearson correlation coefficients and p-values as strings (r1, p1, r2, p2, etc.).
    """
    pvals = []
    for i in range(0, int(len(module_data)/2)):
        x = np.array(module_data[reports[i]]["Per base sequence quality"]).flatten()
        y = np.array(module_data[reports[i+4]]["Per base sequence quality"]).flatten()
        r, p = pearsonr(x, y)
        pvals.extend([str(r),str(p)])
    return sampleID, pvals

def MeasuredCutAdapt(pathList, outfile_name):
    """
    Compute Pearson correlations for CutAdapt report metrics and append them to the output file.

    - For each sample, compares the ground truth and comparative pipeline CutAdapt reports
    - Computes correlations for:
    - Summary metrics
    - Adapter 1 and Adapter 2 statistics
    - Writes results to `outfile_name` as additional columns

    Args:
        pathList (dict): Paths to sample subfolders including library/read group directories.
        outfile_name (str): Path to the output TSV file where results are appended.
    """
    print("Starting CutAdapt stats")
    reports = []
    for entry in pathList["sampleID_lib-rg"]:
        reports.extend(
            sorted(
                [
                    pathjoin(entry, f.name)
                    for f in Path(entry).iterdir()
                    if f.name.endswith("_cutadapt_report.txt")
                ]
            )
        )
    with open(outfile_name, "r") as infile:
        lines = infile.readlines()
    with open(outfile_name, "w") as setfile:
        setfile.write(
            lines[0].strip()
            + "\tSummary_pearson_r\tSummary_pearson_p\tadapter1_length_pearson_r\tadapter1_length_pearson_p\tadapter1_count_pearson_r\tadapter1_count_pearson_p\tadapter1_expect_pearson_r\tadapter1_expect_pearson_p\tadapter1_max_err_pearson_r\tadapter1_max_err_pearson_p\tadapter1_error_counts_pearson_r\tadapter1_error_counts_pearson_p\tadapter2_length_pearson_r\tadapter2_length_pearson_p\tadapter2_count_pearson_r\tadapter2_count_pearson_p\tadapter2_expect_pearson_r\tadapter2_expect_pearson_p\tadapter2_max_err_pearson_r\tadapter2_max_err_pearson_p\tadapter2_error_counts_pearson_r\tadapter2_error_counts_pearson_p\n"
        )
    with open(outfile_name, "a") as outfile:
        linecount = 0
        for i in range(0, len(reports), 2):
            data = []
            with open(reports[i], "r") as file:
                GT_cutrep = file.readlines()
            with open(reports[i + 1], "r") as file:
                CMP_cutrep = file.readlines()
            GT_summary, GT_adapter1, GT_adapter2 = cutrep_reading(GT_cutrep)
            CMP_summary, CMP_adapter1, CMP_adapter2 = cutrep_reading(CMP_cutrep)
            x = list(GT_summary.values())
            y = list(CMP_summary.values())
            r, p = pearsonr(x, y)
            data.extend([str(r), str(p)])
            for dfs in [[GT_adapter1, CMP_adapter1], [GT_adapter2, CMP_adapter2]]:
                for col in dfs[0].columns:
                    x = pd.to_numeric(dfs[0][col], errors="coerce")
                    y = pd.to_numeric(dfs[1][col], errors="coerce")
                    mask = ~x.isna() & ~y.isna()
                    r, p = pearsonr(x[mask], y[mask])
                    data.extend([str(r), str(p)])
            linecount += 1
            outfile.write(lines[linecount].strip() +"\t" + "\t".join(data) + "\n")
            data = []
    print("Stopping CutAdapt stats")


def cutrep_reading(cutrep):
    """
    Parse a CutAdapt report text file and split it into three parts: summary, adapter 1, and adapter 2.

    Args:
        cutrep (list of str): Lines read from a `_cutadapt_report.txt` file.

    Returns:
        tuple:
            dict: Summary statistics with metric names as keys and numeric/string values.
            pandas.DataFrame: Adapter 1 metrics in tabular form.
            pandas.DataFrame: Adapter 2 metrics in tabular form.
    """
    (
        begin_summary,
        end_summary,
        begin_adapter1,
        end_adapter1,
        begin_adapter2,
        end_adapter2,
    ) = 0, 0, 0, 0, 0, 0
    for i in range(0, len(cutrep)):
        if cutrep[i].startswith("==="):
            if "Summary" in cutrep[i]:
                begin_summary = i
            elif "Adapter 1" in cutrep[i]:
                end_summary = i - 1
                begin_adapter1 = i
            elif "Adapter 2" in cutrep[i]:
                end_adapter1 = i - 1
                begin_adapter2 = i
            else:
                print(cutrep[i])
    end_adapter2 = len(cutrep) - 1
    summary = summary_reformatter(cutrep[begin_summary:end_summary])
    adapter1 = adapter_reformatter(cutrep[begin_adapter1:end_adapter1])
    adapter2 = adapter_reformatter(cutrep[begin_adapter2:end_adapter2])
    return summary, adapter1, adapter2


def summary_reformatter(reportpiece):
    """
    Convert the summary section of a CutAdapt report into a key-value dictionary.

    Args:
        reportpiece (list of str): Lines corresponding to the summary section of a CutAdapt report.

    Returns:
        dict: Mapping of metric names to values (strings or numeric).
    """
    data = {}
    for line in reportpiece:
        if any(char.isdigit() for char in line):
            keep = line.strip().replace(",", "").split(":")
            data[keep[0]] = keep[1].strip().split(" ")[0]
    return data


def adapter_reformatter(reportpiece):
    """
    Convert an adapter section of a CutAdapt report into a pandas DataFrame.

    - Corrects column names (e.g., 'error counts' → 'error_counts')

    Args:
        reportpiece (list of str): Lines corresponding to an adapter section of a report.

    Returns:
        pandas.DataFrame: Adapter metrics as a DataFrame.
    """
    table_lines = []
    for line in reportpiece[15:]:
        table_lines.append(line.strip())
    table_lines[0] = table_lines[0].replace("error counts", "error_counts")
    df = pd.read_csv(StringIO("\n".join(table_lines)), sep="\t")
    return df

def MeasuredAlignments(outfile_name, pathstring):
    """
    Compute Pearson correlations for STAR, markdup, and umimarkdup alignment count tables.

    - Compares ground truth (WDL) vs comparative (CWL) count tables
    - Raises an error if:
    - Count table filenames do not match
    - Gene indexes do not match
    - Appends correlation results as new columns in `outfile_name`

    Args:
        outfile_name (str): Path to the output TSV file where results are written.
        pathstring (str): Base directory containing pipeline outputs under `tmp/<group>/WDL` and `tmp/<group>/CWL`.

    Raises:
        ValueError: If count table filenames or gene indexes do not match between pipelines.
    """
    for group in ["starAlign", "markdup", "umimarkdup"]:
        print(f"Starting Alignment analysis for {group}")
        GT_ct = sorted([f.name for f in Path(f"{pathstring}/tmp/{group}/WDL").iterdir()])
        CMP_ct = sorted([f.name for f in Path(f"{pathstring}/tmp/{group}/CWL").iterdir()])
        if GT_ct != CMP_ct:
            raise ValueError(f"{group} countTables do not match!")
        with open(outfile_name, "r") as infile:
            lines = infile.readlines()
        with open(outfile_name, "w") as setfile:
            setfile.write(
                lines[0].strip()
                + f"\t{group}_pearson_r\t{group}_pearson_p\n"
            )
        with open(outfile_name, "a") as file:
            linecount = 0
            for ct in GT_ct:
                GT_ct_df = pd.read_csv(
                        pathjoin(f"{pathstring}/tmp/{group}/WDL", ct),
                        sep="\t",
                        header=None,
                        names=["gene", "count"],
                        index_col=0,
                    )
                CMP_ct_df = pd.read_csv(
                        pathjoin(f"{pathstring}/tmp/{group}/CWL", ct),
                        sep="\t",
                        header=None,
                        names=["gene", "count"],
                        index_col=0,
                )
                if not GT_ct_df.index.equals(CMP_ct_df.index):
                    raise ValueError("Gene Indexes do not match!")
                else:
                    r, p = pearsonr(GT_ct_df.iloc[:, 0], CMP_ct_df.iloc[:, 0])
                    linecount += 1
                    file.write(lines[linecount].strip() + f"\t{r}\t{p}\n")
        print(f"Stopping Alignment analysis for {group}")

def MeasuredCountTables(dataSource, pathList, outfile_name):
    """
    Compute Pearson correlations for fragment-per-gene (count table) expression data.

    - Compares GT vs CMP count tables in `fpg` directories
    - Skips the full_countTable specified in `dataSource`
    - Writes log2-transformed correlation results to `outfile_name`
    - Raises an error if table names or gene indexes do not match

    Args:
        dataSource (dict): Pipeline input components including 'full_countTable'.
        pathList (dict): Paths to GT and CMP fragment-per-gene count tables.
        outfile_name (str): Path to the output TSV file.

    Raises:
        ValueError: If count table filenames or gene indexes do not match between pipelines.
    """
    print("Starting CountTable stats")
    GT_fpg = sorted([f.name for f in Path(pathList["GT_fpg_expression"]).iterdir()])
    CMP_fpg = sorted([f.name for f in Path(pathList["CMP_fpg_expression"]).iterdir()])

    if GT_fpg != CMP_fpg:
        raise ValueError("Fragment_per_Gene countTables do not match!")
    with open(outfile_name, "r") as infile:
        lines = infile.readlines()
    with open(outfile_name, "w") as setfile:
        setfile.write(
            lines[0].strip()
            + "\tcounttables(log2trf)_pearson_r\tcounttables(log2trf)_pearson_p\n"
        )
    with open(outfile_name, "a") as file:
        linecount = 0
        for fpg in GT_fpg:
            if fpg != dataSource["full_countTable"]:
                GT_fpg_df = np.log2(
                    pd.read_csv(
                        pathjoin(pathList["GT_fpg_expression"], fpg),
                        sep="\t",
                        header=None,
                        names=["gene", "count"],
                        index_col=0,
                    )
                    + 1
                )
                CMP_fpg_df = np.log2(
                    pd.read_csv(
                        pathjoin(pathList["CMP_fpg_expression"], fpg),
                        sep="\t",
                        header=None,
                        names=["gene", "count"],
                        index_col=0,
                    )
                    + 1
                )
                if not GT_fpg_df.index.equals(CMP_fpg_df.index):
                    raise ValueError("Gene Indexes do not match!")
                else:
                    r, p = pearsonr(GT_fpg_df.iloc[:, 0], CMP_fpg_df.iloc[:, 0])
                    linecount += 1
                    file.write(lines[linecount].strip() + f"\t{r}\t{p}\n")
    print("Stopping CountTable stats")


def main():
    """
    Main function that orchestrates the RNA-seq pipeline validation workflow:

    1. Reads inputs from `inputs.yml` using `retrieval()`
    2. Builds all necessary paths with `pathing()`
    3. Initializes the output TSV file
    4. Runs:
    - `MeasuredFastQC` for FastQC correlations
    - `MeasuredCutAdapt` for CutAdapt correlations
    - `MeasuredAlignments` for alignment table correlations
    - `MeasuredCountTables` for fragment-per-gene correlations
    5. Appends results to the output file
    """
    outfile_name = "test_stats.tsv"
    dataSource, cutadapt, reads = retrieval("inputs.yml")
    pathList, sampleIDs = pathing(dataSource)
    with open(outfile_name, "w") as file:
        file.write("SampleIDs\n" + "\n".join(sampleIDs) + "\n")
    MeasuredFastQC(pathList, sampleIDs, outfile_name, [cutadapt, reads])
    MeasuredCutAdapt(pathList, outfile_name)
    MeasuredAlignments(outfile_name, ".")
    MeasuredCountTables(dataSource, pathList, outfile_name)


if __name__ == "__main__":
    main()

