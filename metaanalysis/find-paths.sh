echo "Process file list $1 to output $2 on $3"

if [ ! -f "$1" ]
then
	echo "Input file does not exist."
	exit 3
fi

if [ -f "$2" ]
then
	echo "Output file exists - please delete it."
	exit 3
fi

for FN in `cat $1`
do
	echo -n "Find path for $FN: "
	MYPATH=`find /storage/cleaning/ckdgenR5 -type d -name "${FN}*"`
	if [ "$MYPATH" == "" ]
	then
        	        echo "NOT FOUND => directory MISSING!!"
	fi

	MYPATHdata=`find /storage/cleaning/ckdgenR5/"${FN}"/data -type f -name "*$3*.gz"`
        if [ "$MYPATHdata" == "" ]
        then
                        echo "NOT FOUND => FILE MISSING!!"
        else
		
		
		echo $MYPATHdata
		echo $MYPATHdata >> $2
	fi
done
