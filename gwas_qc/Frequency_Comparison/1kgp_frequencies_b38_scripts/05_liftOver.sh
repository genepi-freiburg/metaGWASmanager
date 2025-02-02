mkdir -p liftOver_output liftOver_error

for CHR in `seq 1 22` X
do
echo "Chr = $CHR"
./liftOver liftOver_input/1kgp_positions.chr$CHR.bed hg19ToHg38.over.chain.gz liftOver_output/1kgp_positions.b38.chr$CHR.bed liftOver_error/1kgp_chr$CHR.txt
done

