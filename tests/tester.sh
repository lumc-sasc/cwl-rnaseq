#!/bin/bash

# Initialize
args=("$@")
clean_args=()
keep_temp=false
testdir=tests
jobdir=jobs
tempdir=tmp
runpytest=true
copydir=""

# Parse arguments
for ((i=0; i<${#args[@]}; i++)); do
    case "${args[i]}" in
        -td) # test containing directory
            if [[ -z "${args[i+1]}" || "${args[i+1]}" == -* ]]; then
                echo "Error: -td requires a directory name argument." >&2
                exit 1
            fi
            testdir="${args[i+1]}"
            ((i++))
            ;;
        -jd)  # job containing directory
            if [[ -z "${args[i+1]}" || "${args[i+1]}" == -* ]]; then
                echo "Error: -jd requires a directory name argument." >&2
                exit 1
            fi
            jobdir="${args[i+1]}"
            ((i++))
            ;;
        -tmpd)  # temporary directory
            if [[ -z "${args[i+1]}" || "${args[i+1]}" == -* ]]; then
                echo "Error: -tmpd requires a directory name argument." >&2
                exit 1
            fi
            tempdir="${args[i+1]}"
            ((i++))
            ;;
        -cd) # COPYDIR replacement
            if [[ -z "${args[i+1]}" || "${args[i+1]}" == -* ]]; then
                echo "Error: -cd requires a directory name argument." >&2
                exit 1
            fi
            copydir="${args[i+1]}"
            ((i++))
            ;;
        -ktd) # keep temporary directory
            keep_temp=true
            ;;
        -nt) # do not run pytest
            runpytest=false
            ;;
    esac
done

if [[ -z "$copydir" ]]; then
    echo "Error: -cd <copydir> is mandatory." >&2
    exit 1
fi

testdir=$(realpath "$testdir")
jobdir=$(realpath "$jobdir")
tempdir=$(realpath "$tempdir")
copydir=$(realpath "$copydir")

mkdir -p "$tempdir/tests" "$tempdir/jobs"
cp -r "$testdir/"* "$tempdir/tests/"
cp -r "$jobdir/"/* "$tempdir/jobs/"

find "$tempdir/tests" -type f \( -name "*.yml" -o -name "*.yaml" \) -exec \
    sed -i "s#tests/jobs#${tempdir}/jobs#g" {} +

find "$tempdir/tests" -type f \( -name "*.yml" -o -name "*.yaml" \) -exec \
    sed -i "s#COPYDIR#${copydir}#g" {} +

shopt -s nullglob
for jobfile in "$tempdir"/jobs/*.yml "$tempdir"/jobs/*.yaml; do
    [[ -f "$jobfile" ]] || continue
    # Replace each location line
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^([[:space:]]*location:[[:space:]]*)(.*) ]]; then
            prefix="${BASH_REMATCH[1]}"
            relpath="${BASH_REMATCH[2]}"
            abspath=$(realpath --canonicalize-existing "$jobdir/$relpath" 2>/dev/null || echo "$jobdir/$relpath")
            # Use printf to preserve spaces and newline
            printf "%s%s\n" "$prefix" "$abspath"
        else
            printf "%s\n" "$line"
        fi
    done < "$jobfile" > "$jobfile.tmp"
    mv "$jobfile.tmp" "$jobfile"
done
shopt -u nullglob
if $runpytest; then
    PYTHONUNBUFFERED=1 pytest -s --symlink "$tempdir/tests" | tee "${logfile:-tests.log}"
fi

if ! $keep_temp; then
    rm -rf "$tempdir"
fi