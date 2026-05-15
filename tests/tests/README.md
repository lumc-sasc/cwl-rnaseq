# Tests

Do not run these tests directly. First run `tester.sh` targeting this directory and the jobs directory.

To run pytest directly (As ran from cwl-rnaseq):
`bash tests/tester.sh -td tests/tests -jd tests/jobs -tmd tests/tmp`

To get transformed directories (As ran from cwl-rnaseq):
`bash tests/tester.sh -td tests/tests -jd tests/jobs -tmd tests/tmp -ktmp -np`