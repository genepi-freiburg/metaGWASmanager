source ./folders.config.sh

DIR=$CLEANING_DIR

NONO=-n
rename $NONO s/_EA_/_EUR_/ $DIR/*/data/*
rename $NONO s/_AA_/_AFR_/ $DIR/*/data/*
rename $NONO s/_chrAll_/_/ $DIR/*/data/*
