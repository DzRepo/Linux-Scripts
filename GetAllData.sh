# Get all the data for a search, iterating through next tokens

rm -f TempResults.json
rm -f AllResults.json

# load settings
source GetAllData.cfg

#build query
CMD="curl -s -u${Username}:${Password} -oTempResults.json \"${Endpoint}\" -d '{${Query}}'"
#echo " "
#echo $CMD
#echo " "
eval $CMD

declare -i RequestCount
RequestCount=1
FirstDate=$(jq -r '.results[0].postedTime'  TempResults.json)
echo -ne "\r Requests: ${RequestCount} - $FirstDate " 

declare -x NextToken=""

echo "{ \"results\":[" > AllResults.json
NextToken=$(jq -r  '.next'  TempResults.json)
jq -c  '.results[]'  TempResults.json | sed 's/$/,/' >> AllResults.json

# echo "Next Token = ${NextToken}"

while [ ! "$NextToken" = "null" ]
do
	OldNextToken=$NextToken
	echo "," >> AllResults.json
	PostCommand="${Query},\"next\":\"${NextToken}\""
	CMD="curl -s -u${Username}:${Password} -oTempResults.json \"${Endpoint}\" -d '{${PostCommand}}'" 
	#echo " "
	#echo $CMD
	#echo " "
	eval $CMD

	RequestCount=$[RequestCount + 1]		
	ErrorMsg=$(jq -c '.error.message'  TempResults.json)
		
	if [ -z "$ErrorMsg" ] 
	then
		echo "Error: $ErrorMsg"
	else
		jq -c  '.results[]'  TempResults.json | sed 's/$/,/' >> AllResults.json
		NextToken=$(jq -r  '.next'  TempResults.json)
		FirstDate=$(jq -r '.results[0].postedTime'  TempResults.json)
		
		if [ "${FirstDate}" = "null" ]
		then
			echo -ne "\r Requests: ${RequestCount} - No records returned.     "
		else
			echo -ne "\r Requests: ${RequestCount} - $FirstDate " 
		fi

		if [ "${NextToken}" = "null" ]	
		then
			echo -ne "\r Finished processing.  Data in GetAllData.json      "
			echo " " 
			echo "Total Requests: ${RequestCount}"
			break
		else
			if [ "$NextToken" = "Old$NextToken" ]
			then
				echo "Duplicate Token Detected"
				break
			fi
		fi	
	fi
	
done
sed '$ s/.$//' AllResults.json > TempResults.json
echo "]}" >> TempResults.json
sed  's/,//' TempResults.json | sed '/^\s*$/d' > GetAllData.json
TotalRecords=$(jq '.[] | length' GetAllData.json)
echo "Total Activities: ${TotalRecords}"
