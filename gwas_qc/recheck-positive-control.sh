WD=`pwd`
cd /storage/cleaning/ckdgenR5
for FN in `ls`
do
cd $FN
/storage/scripts/ckdgenR5/gwas_qc/03-check-positive-controls.sh
cd ..
done
ls */03-check*
cd $WD
