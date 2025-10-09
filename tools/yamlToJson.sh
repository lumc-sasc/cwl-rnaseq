#!/bin/bash
set -e

yaml="$1"
if [ "$2" = "." ]; then
    outputJson="$3"
else
    outputJson="$2/$3"
    mkdir -p $2
fi
python <<CODE
import json
import yaml
with open("${yaml}", "r") as input_yaml:
    content = yaml.safe_load(input_yaml)
with open("${outputJson}", "w") as output_json:
    json.dump(content, output_json)
CODE
