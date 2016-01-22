# Get all the data for a search, iterating through next tokens

rm -f TempResults.json
rm -f AllResults.json

# load settings
source GetAllData.cfg

CMD="curl -s -u${Username}:${Password} -oTempResults.json \"${Endpoint}\" -d '{${Query}}'"
# echo $CMD
eval $CMD

declare -i RequestCount
RequestCount=1
RED='\033[0;31m'

ErrorMsg=$(jq -c '.error.message'  TempResults.json)


if [ ! "$ErrorMsg" = "null" ]
then
	printf "${RED} 	Error: $ErrorMsg NC='\033[0m'"
	echo ""
else
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
		# StagingCMD="curl -s -u${Username}:${Password} -oTempResults.json -H 'Dtab-Local: /s/datadelivery-search/tweethunter => /srv#/staging1/atla/datadelivery-search-stg1/tweethunter' \"${Endpoint}\" -d '{${PostCommand}}'" 
		
		CMD="curl -s -u${Username}:${Password} -oTempResults.json \"${Endpoint}\" -d '{${PostCommand}}'" 
		# echo " "
		# echo $PostCommand
		# echo " "
		eval $CMD

		RequestCount=$[RequestCount + 1]		
		ErrorMsg=$(jq -c '.error.message'  TempResults.json)
		
		if [ -z "$ErrorMsg" ] 
		then
			echo "Error: $ErrorMsg"
		else
			jq -c  '.results[]'  TempResults.json | sed 's/$/,/' >> AllResults.json
			NextToken=$(jq -r  '.next'  TempResults.json)
			# echo " "
			# echo "Next Token: $NextToken"
			FirstDate=$(jq -r '.results[0].postedTime'  TempResults.json)
		
			FirstDateCounts=$(jq -r '.results[0].timePeriod'  TempResults.json)
		
			if [ "${FirstDate}" = "null" ]
			then
			   if [ "${FirstDateCounts}" = "null" ]
			   then
			      echo -ne "\r Requests: ${RequestCount} - No records returned.     "
			   else
			      echo -ne "\r Requests: ${RequestCount} - $FirstDateCounts " 
			   fi
			else
				echo -ne "\r Requests: ${RequestCount} - $FirstDate " 
			fi

			if [ ! "${NextToken}" = "null" ]	
			then
				if [ "$NextToken" = "Old$NextToken" ]
				then
					echo "Duplicate Token Detected"
					break
				fi
			fi	
		fi	
	done
	echo -ne "\rFinished processing.  "
	echo "Data in GetAllData.json      "
	echo "Total Requests: ${RequestCount}"
	sed '$ s/.$//' AllResults.json > AllTempResults.json
	echo "]}" >> AllTempResults.json
	sed  's/,//' AllTempResults.json | sed '/^\s*$/d' > GetAllData.json
	TotalRecords=$(jq '.[] | length' GetAllData.json)
	echo "Total Activities: ${TotalRecords}"
fi
