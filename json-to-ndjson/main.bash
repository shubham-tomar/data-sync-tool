#!/bin/bash

run_in_ll () {
        day=$1
        shift
        local batch_files=("$@")
        echo "day: "$day
        local batch_output_file="$(head --bytes=40 /dev/urandom | base64 | tr -c -d 'a-zA-Z')_output_file"

        for individual_file in "${batch_files[@]}"; do
            echo "Processing file: $individual_file"
            gsutil cat $individual_file | zcat - | wc -l >> $batch_output_file
            # gsutil cat $individual_file | zcat - | json-to-ndjson >> $batch_output_file
        done
        echo $batch_output_file
        cat $batch_output_file | wc -l
        rm $batch_output_file
    }

for i in $(seq -w 01 01); do
    day=2023-01-$i
    echo $day
    echo $i
    export -f run_in_ll
    export i

    files_list=()
    while IFS= read -r line; do
        files_list+=("$line")
    done < <(gsutil ls gs://bucket-name/2023/09/01/)
    (gsutil ls gs://bucket-name/2023/09/01/) > all_files

    # printf '%s\0' "${files_list[@]}" | xargs -0 -n 10 -P 10 -I {} bash -c 'sleep 3; run_in_ll "$i" "$@"' _ {}
    cat all_files | xargs -n 4 bash -c 'sleep 3;  arr=$(echo "$0" "$@"); run_in_ll "$i" "$arr" '

done
