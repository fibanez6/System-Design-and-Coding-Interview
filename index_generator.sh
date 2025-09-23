#!/bin/bash

# Iterate through each subfolder in the current directory

# for folder in */ ; do
#     echo "== ${folder%/}"
# done

# Array of directory names to exclude
EXCLUDE_DIRS=("img" ".git" ".github" "CtCI-6th-Edition" "coding-interview-university")
SCRIPT_PATH="$(pwd)"
ROOT_README="$SCRIPT_PATH/README.adoc"

is_excluded() {
    local name="$1"
    for ex in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$name" == "$ex" || "$name" == *"$ex"* ]]; then
            return 0
        fi
    done
    return 1
}

replace_special_chars() {
    local str="$1"
    str="${str//_/ }"  # Replace underscores with spaces
    str="${str//-/ }"  # Replace dashes with spaces
    echo "$str"
}

generate_index() {
    local path="$1"
    local level="$2"
    local parent_folder="$3"
    for folder in "$path"/*/; do
        [ -d "$folder" ] || continue
        basename=$(basename "$folder")
        if is_excluded "$basename"; then
            continue
        fi
        prefix=$(printf '=%.0s' $(seq 1 "$level"))
        echo "${prefix} $(replace_special_chars "$basename")"
        generate_index "$folder" $((level + 1))
    done

    find "$path" -maxdepth 1 \
        -type f \
        -name "*.adoc" -o \
        -name "*.pdf" | sort | while read -r filepath; do

        cleanpath="${filepath#./}"
        cleanpath="${cleanpath//\/\///}" # replace // to /
        cleanpath="${cleanpath// /%20}" # replace space to %20 for URL
        cleanpath="${cleanpath//:/%3A}" # replace : to %3A for URL

        # folder=$(dirname "$cleanpath")
        filename=$(basename "$filepath" .adoc)
        text=$(replace_special_chars $filename)

        if [[ "$filename" == "README" ]]; then
            continue
        fi
        
        if [[ -n "$parent_folder" ]]; then
            echo "* xref:${parent_folder}/${cleanpath}[$text]"
        else
            echo "* xref:${cleanpath}[$text]"
        fi        
    done
    echo ""
}


generate_readme() {
    local path="$1"
    OUTPUT_FILE="README.adoc"

    if [ ! -d "$path" ]; then
        echo "Directory '$path' does not exist"
        return 1
    fi

    cd "$path" || exit 1
    
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    current_folder="$(basename "$script_dir")"
    # Generate the index and save to index.adoc
    echo "= $(replace_special_chars "$current_folder")" > "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "link:https://github.com/fibanez6/System-Design-and-Coding-Interview[System Design and Coding Interview]" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    # Start printing from the current directory with level 2 (==)
    generate_index '.' 2 >> "$OUTPUT_FILE"


    # Also append to the root README
    echo "== $(replace_special_chars "$current_folder")" >> "$ROOT_README"
    echo "" >> "$ROOT_README"
    generate_index '.' 2 $current_folder >> "$ROOT_README"
    cd "$SCRIPT_PATH" || exit 1
}


# generate_readme 'AWS_Certified_Data_Engineer_Associate'
# generate_readme 'AWS_Certified_Data_Engineer_Associate/DEA-C01'

echo "= System Design and Coding Interview" > "$ROOT_README"
echo "link:https://github.com/fibanez6/System-Design-and-Coding-Interview[System Design and Coding Interview]" >> "$ROOT_README"
echo "" >> "$ROOT_README"


find . \
 -path "*/.git" -prune -o \
 -name "README.adoc" -prune -o \
 -mindepth 1 -maxdepth 2 -type d -print | while read -r dir; do
    basename=$(basename "$dir")
    cleanpath="${dir#./}"
    if is_excluded "$cleanpath"; then
        echo "Skipping excluded directory: $cleanpath"
        continue
    fi
    echo "Generating index for: $cleanpath"
    generate_readme "$cleanpath"
done
