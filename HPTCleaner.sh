SAVEIFS=$IFS
rm -f filtered.json
rm -f activities*.jsom
inputfilecount=`ls -l "$@" | wc -l`
echo "Number of files to decompress: $(($inputfilecount))"
IFS=$(echo -en "\n\b")

filecount=(0);

if [ $inputfilecount -eq 0 ] ; then
	echo "No files found matching the pattern $1 - skipping decompress phase."
	
else
	for f in "$@"
	do
    	filecount=$((filecount+1))
		echo -en "Decompressing '$f' \r"
		gzip -d -f -N $f
	done
fi

if [ $filecount -gt 0 ] ; then 
	echo "Decompressed $(($filecount)) files.                                                               "
fi

i=1
sp="/-\|"
Files="activities*.json"
echo -ne " "
IDLine="Id";
filecount=`ls -l activities*.json | wc -l`
filecounter=(0);

for f in $Files
do
    filecounter=$((filecounter+1))
	LINES=$(wc -l < "$f")
	echo -ne "        of ($(($LINES))) - Combining file $(($filecounter)) of $(($filecount))  - '$f' \r"
    counter=(0)
    while read -r line
	do
    	name=$line
    	if [[ $line == *"id"* ]]; then
    		counter=$((counter+1))
    	    echo -en "($counter) \r"
    		echo "$line" >> filtered.json
    	fi
	done < $f

done

IFS=$SAVEIFS
echo "Decompressing & Filtering Finished.                                                                        "
ls -l filtered.json 
