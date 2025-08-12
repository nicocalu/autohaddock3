#!/usr/bin/env python
"""
A robust script to convert mmCIF files to PDB format, handling multi-character
chain IDs by renaming them, a common requirement for PDB compatibility.

Usage:
    python convert_cif_to_pdb.py <input.cif> [output.pdb]

Requires BioPython: `pip install biopython`
"""

import sys
import argparse
import logging
from Bio.PDB import MMCIFParser, PDBIO

class OutOfChainsError(Exception):
    """Raised when no more single-character chain IDs are available."""
    pass

def int_to_chain(i, base=62):
    """
    Converts a positive integer to a valid single-character chain ID.
    Chain IDs cycle through A-Z, 0-9, a-z.
    """
    if not 0 <= i < base:
        raise ValueError(f"Integer {i} is out of the valid range for base {base}")

    if i < 26:
        return chr(ord("A") + i)
    elif i < 36:
        return str(i - 26)
    else: # i < 62
        return chr(ord("a") + i - 36)

def rename_chains(structure):
    """
    Renames multi-character chains to single-character chains required by PDB format.

    - Existing single-letter chains are preserved.
    - Multi-letter chains are renamed to the next available single character.
    - If more than 62 chains need renaming, raises OutOfChainsError.

    Returns a map of {new_id: old_id}. Modifies the structure in-place.
    """
    next_chain_idx = 0
    
    # Chains that are already single-character and valid
    valid_chains = {c.id for c in structure.get_chains() if len(c.id) == 1}
    
    # Map of new chain IDs to original IDs
    chain_map = {cid: cid for cid in valid_chains}

    for chain in structure.get_chains():
        if len(chain.id) != 1:
            # Find the next available single-character ID
            new_id = int_to_chain(next_chain_idx)
            while new_id in valid_chains:
                next_chain_idx += 1
                if next_chain_idx >= 62:
                    raise OutOfChainsError("Exceeded 62 chains, cannot generate new unique chain IDs.")
                new_id = int_to_chain(next_chain_idx)

            # Assign the new ID
            chain_map[new_id] = chain.id
            chain.id = new_id
            valid_chains.add(new_id)
            next_chain_idx += 1
            
    return chain_map

def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description='Convert mmCIF file to PDB format, renaming long chain IDs.',
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("cif_file", help="Path to the input mmCIF file.")
    parser.add_argument("pdb_file", nargs="?", help="Path for the output PDB file.\n(default: adds .pdb to the input filename)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable detailed logging of operations.")
    args = parser.parse_args()

    # Configure logging
    log_level = logging.INFO if args.verbose else logging.WARNING
    logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

    # Determine output filename if not provided
    pdb_file = args.pdb_file or args.cif_file.rsplit('.', 1)[0] + ".pdb"
    
    # --- Main Conversion Logic ---
    logging.info(f"Input CIF: {args.cif_file}")
    logging.info(f"Output PDB: {pdb_file}")

    # 1. Parse the mmCIF file
    parser = MMCIFParser()
    try:
        structure = parser.get_structure("cif_structure", args.cif_file)
    except FileNotFoundError:
        logging.error(f"Input file not found: {args.cif_file}")
        sys.exit(1)

    # 2. Rename chains if necessary
    try:
        chain_map = rename_chains(structure)
        for new, old in chain_map.items():
            if new != old:
                logging.info(f"Renamed chain '{old}' to '{new}' for PDB compatibility.")
    except OutOfChainsError as e:
        logging.error(f"Failed to convert: {e}")
        sys.exit(1)

    # 3. Write the PDB file
    io = PDBIO()
    io.set_structure(structure)
    io.save(pdb_file)
    
    logging.info(f"Successfully converted {args.cif_file} to {pdb_file}")

if __name__ == "__main__":
    main()