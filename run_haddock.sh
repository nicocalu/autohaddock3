#!/bin/bash
# filepath: \autohaddock3\run_haddock.sh

# Check if configs directory exists
if [ ! -d "./configs" ]; then
    echo "Error: ./configs directory not found"
    exit 1
fi

echo "Starting HADDOCK runs..."

for cfg in ./configs/*-init.cfg; do
    if [ -f "$cfg" ]; then
        echo "Running HADDOCK for $cfg"
        haddock3 "$cfg"
        echo "---"
    fi
done

echo "All HADDOCK runs completed."
date
#tar -czvf results.tar.gz runs/*/analysis