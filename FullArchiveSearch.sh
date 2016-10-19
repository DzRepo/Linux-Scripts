
# FullArchiveSearch.sh
# Get all the data or counts for a  full archive search, iterating through next tokens
# Consolidates all results into a single file.
# All settings stored in FullArchiveSearch.cfg
#
# Not supported by GNIP or Twitter.  Open source software.
#
# Questions or suggestions?  Steven Dzilvelis @SteveDz
# Requires: sed & jq
#

rm -f TempResults.json
rm -f AllResults.json

# load settings
source FullArchiveSearch.cfg

#Override paramenters with "Search" and "Destination"

if [ ! -z "$1" ] 
then
	searchQuery="$1"
fi
echo "  Searching for: $searchQuery"

if [ ! -z "$2" ] 
then
	Destination="$2"
fi

if [ ! -z "$3" ] 
then
	fromDate="$3"
fi

if [ ! -z "$4" ] 
then
	toDate="$4"
fi

if [ ! -z "$5" ] 
then
	QueryType="$5"
fi


if [ "$QueryType" == "Data" ]
then
	echo "Query type is Data"
else
	echo "Query type is Counts"
fi

echo "Searching for: $searchQuery" 
echo "Writing results to: $Destination"
if [ ! -z "$fromDate" ]
then
	echo "From Date: $fromDate"
fi
if [ ! -z "$toDate" ]
then
	echo "  To Date: $toDate"
fi

#build query
if [ ! -z "$fromDate" ]
then
	SQuery="$SQuery\"fromDate\":\"$fromDate\"," 
fi

if [ ! -z "$toDate" ]
then
	SQuery="$SQuery\"toDate\":\"$toDate\"," 
fi

if [ "$QueryType" == "Data" ]
then
	if [ $maxResults -gt 0 ]
	then
		SQuery="$SQuery\"maxResults\":$maxResults," 
	fi
	SQuery="$SQuery\"query\":\"$searchQuery\"" 
	CMD="curl -s -u${Username}:${Password} -oTempResults.json ${Endpoint}/${Account}/${Label}.json -d '{${SQuery}}'"
else
	if [ ! -z "$bucket" ]
	then
		SQuery="$SQuery\"bucket\":\"$bucket\"," 
	fi
	SQuery="$SQuery\"query\":\"$searchQuery\""  
	CMD="curl -s -u${Username}:${Password} -oTempResults.json ${Endpoint}/${Account}/${Label}/counts.json -d '{${SQuery}}'"
fi
echo " "
# echo $CMD
eval $CMD


declare -i RequestCount
RequestCount=1
RED='\033[0;31m'
NC='\033[0m'

ErrorMsg=$(jq -c '.error.message'  TempResults.json)

if [ ! "$ErrorMsg" = "null" ]
then
	printf "${RED} 	Error: $ErrorMsg NC='\033[0m'"
	echo ""
else
	if [ "$QueryType" == "Data" ]
	then
		FirstDate=$(jq -r '.results[0].postedTime'  TempResults.json)
	else
		FirstDate=$(jq -r '.results[0].timePeriod'  TempResults.json)
	fi
	echo -ne "\r Requests: ${RequestCount} - $FirstDate " 

	declare -x NextToken=""

	echo "{ \"results\":[" > AllResults.json
	NextToken=$(jq -r  '.next'  TempResults.json)
	jq -c  '.results[]'  TempResults.json | sed 's/$/,/' >> AllResults.json

	while [ ! "$NextToken" = "null" ]
	do
		OldNextToken=$NextToken
		PostCommand="${SQuery},\"next\":\"${NextToken}\""
		if [ "$QueryType" == "Data" ]
			then
			CMD="curl -s -u${Username}:${Password} -oTempResults.json ${Endpoint}/${Account}/${Label}.json -d '{${PostCommand}}'"
		else
			CMD="curl -s -u${Username}:${Password} -oTempResults.json ${Endpoint}/${Account}/${Label}/counts.json -d '{${PostCommand}}'"
		fi
		echo " "
#		echo $CMD
		eval $CMD

		RequestCount=$[RequestCount + 1]		
		ErrorMsg=$(jq -cr '.error.message'  TempResults.json)
		
		if [ ! "$ErrorMsg" == "null" ];
		then
			echo ""
			echo -e "$RED Error: $ErrorMsg $NC"
			
			if [[ ! $ErrorMsg == *"retry"* ]]
			then
			    break;
			fi
			
		else
			jq -c  '.results[]'  TempResults.json | sed 's/$/,/' >> AllResults.json
			NextToken=$(jq -r  '.next'  TempResults.json)
			
			if [ "$QueryType" == "Data" ]
			then
				FirstDate=$(jq -r '.results[0].postedTime'  TempResults.json)
			else
				FirstDate=$(jq -r '.results[0].timePeriod'  TempResults.json)
			fi
	
			FirstDateCounts=$(jq -r '.results[0].timePeriod'  TempResults.json)
			
			if [ "$QueryType" == "Data" ]
			then	
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
			else
				echo -ne "\r Requests: ${RequestCount} - $FirstDate "  
			fi

			if [ "${NextToken}" = "null" ]	
			then
				echo " " 
				echo -ne "\r Finished processing                          "
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
	
	echo ""
	
	#post process
	if [ "$ErrorMsg" == "null" ];
	then
		sed '$ s/.$//' AllResults.json > AllTempResults.json
		echo "]}" >> AllTempResults.json
		
		if [ "$QueryType" == "Data" ]
		then		
			sed  's/,//' AllTempResults.json | sed '/^\s*$/d' > $Destination
			TotalRecords=$(jq '.[] | length' $Destination)
			echo "Total Activities: ${TotalRecords}"
		else
			mv AllTempResults.json $Destination
			TotalRecords=$(jq '.[] | length' $Destination)	
			echo "Total # of buckets: ${TotalRecords}"
			TotalCount=$(jq "[.results[].count] | add" $Destination)
			echo "Total of Counts: ${TotalCount}"
		fi
	fi
fi