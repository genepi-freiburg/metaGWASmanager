IMAGE=/home/mwuttke/SingularityTest/gwasinspector.simg
MYDIR=/storage/uploads/ckdgenR5/assoc/XXXXXX
singularity exec \
	--bind /storage \
	$IMAGE \
	cd $MYDIR Rscript /storage/scripts/ckdgenR5/gwas_qc/GWASinspector/gwasinspector.R \
	2>&1 | tee run_gwasinspector.log

