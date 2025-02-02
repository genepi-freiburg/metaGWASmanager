tar xzf 1000GP_Phase3_chrX.tgz --wildcards *legend.gz
tar xzf 1000GP_Phase3.tgz --wildcards *legend.gz
mkdir -p legend
mv *legend.gz legend
mv 1000GP_Phase3/*.legend.gz legend/
rmdir 1000GP_Phase3/

