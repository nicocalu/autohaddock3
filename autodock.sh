#!/bin/bash

# Check if folds directory exists
if [ ! -d "./folds" ]; then
    echo "Error: ./folds directory not found"
    exit 1
fi

# Check if template config exists
if [ ! -f "init.cfg" ]; then
    echo "Error: init.cfg template not found"
    exit 1
fi

# Check if interactions directory exists
if [ ! -d "./interactions" ]; then
    echo "Error: ./interactions directory not found"
    exit 1
fi

# Generate restraints from active residue files (NEED THE PDB FILES)
# cd interactions
# sed 's/,/ /g' Nb_interactions.txt > Nb_actpass.txt
# sed 's/,/ /g' Ag_interactions.txt > Ag_actpass.txt
# haddock3-restraints passive_from_active extra/T3CL11.pdb $(cat Nb_interactions.txt) >> Nb_actpass.txt
# haddock3-restraints passive_from_active extra/B7-H3.pdb $(cat Ag_interactions) >> Ag_actpass.txt
# haddock3-restraints active_passive_to_ambig interactions/Nb_actpass.txt interactions/Ag_actpass.txt --segid-one A --segid-two B > restraints.tbl
# cd ..
# mv interactions/restraints.tbl restraints.tbl

echo "Starting configuration file generation..."

# Counter for created configs
config_count=0

mkdir -p configs
mkdir -p pdb

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

    pdb_file="pdb/${name}.pdb"
    
    # Convert CIF to PDB if not already converted
    if [ ! -f "$pdb_file" ]; then
        echo "Converting $cif_file to $pdb_file"
        python ./cif2pdb.py "$cif_file" "$pdb_file"
        if [ $? -ne 0 ]; then
            echo "Error: Conversion failed for $cif_file"
            continue
        fi
    else
        echo "PDB file already exists: $pdb_file"
    fi
    
    # Create config file name
    
    config_file="configs/${name}-init.cfg"
    
    # Create configuration file by replacing placeholders in template
    echo "Creating configuration file: $config_file"
    
    # Replace [name] placeholders: first one with the name for run_dir, second one with the cif file path
    sed -e "s|run_dir = \"\[name\]\"|run_dir = \"runs/$name\"|" \
        -e "s|\"\[name\]\",|\"$pdb_file\",|" \
        init.cfg > "$config_file"
    
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