#!/bin/bash

# Check if folds directory exists
if [ ! -d "./folds" ]; then
    echo "Error: ./folds directory not found"
    exit 1
fi

# Check if template config exists
if [ ! -f "haddock3test/init.cfg" ]; then
    echo "Error: init.cfg template not found"
    exit 1
fi

echo "Starting configuration file generation..."

# Counter for created configs
config_count=0

# Scan all folders in ./folds
for folder in ./folds/*/; do
    if [ ! -d "$folder" ]; then
        continue
    fi
    
    # Extract folder name (remove ./folds/ prefix and trailing /)
    folder_name=$(basename "$folder")
    
    # Extract the name part (assuming format is nb_[name])
    if [[ $folder_name =~ ^nb_(.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
    else
        echo "Warning: Folder $folder_name doesn't match expected pattern nb_[name], skipping..."
        continue
    fi
    
    # Look for the first .cif file in the folder
    cif_file=$(find "$folder" -name "*.cif" -type f | head -n 1)
    
    if [ -z "$cif_file" ]; then
        echo "Warning: No .cif file found in $folder, skipping..."
        continue
    fi
    
    echo "Processing folder: $folder_name"
    echo "Using .cif file: $cif_file"
    
    # Create config file name
    config_file="haddock3test/${name}-init.cfg"
    
    # Create configuration file by replacing placeholders in template
    echo "Creating configuration file: $config_file"
    
    # Replace [name] placeholders: first one with the name for run_dir, second one with the cif file path
    sed -e "s|run_dir = \"\[name\]\"|run_dir = \"$name\"|" \
        -e "s|\"\[name\]\",|\"$cif_file\",|" \
        haddock3test/init.cfg > "$config_file"
    
    # Check if config file was created successfully
    if [ -f "$config_file" ]; then
        ((config_count++))
        echo "Successfully created: $config_file"
    else
        echo "Error: Failed to create $config_file"
    fi
    
    echo "---"
done

echo ""
echo "Configuration file generation completed!"
echo "Created $config_count configuration files."

if [ $config_count -eq 0 ]; then
    echo "No configuration files were created."
    exit 1
fi

echo "Generated files: *-init.cfg"