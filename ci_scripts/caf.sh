#!/bin/bash

# Root directory to process (current directory)
ROOT_DIR="../"

# Compression format (aac / ima4 / alac)
FORMAT="aac"
CAFF_FORMAT="caff"

echo "Starting recursive compression of CAF files..."
echo "Root directory: $ROOT_DIR"
echo "Compression codec: $FORMAT"
echo

find "$ROOT_DIR" -type f -name "*.caf" | while read -r file; do
    echo "Compressing: $file"

    # Force output to the same file (unsafe)
    afconvert "$file" "$file" -d "$FORMAT" -f "$CAFF_FORMAT"

    if [ $? -eq 0 ]; then
        echo "Done: $file"
    else
        echo "⚠️ Conversion failed: $file (may be corrupted)"
    fi

    echo
done

echo "All done!"
