module load mamba
git clone https://github.com/nicocalu/autohaddock3
cd autohaddock3
mamba env create -f environment.yml
mamba activate haddock3
chmod +x autodock.sh
./autodock.sh
echo "***********************************************"
echo "**** DONT FORGET TO UPLOAD THE PDB DATA!!! ****"
echo "***********************************************"