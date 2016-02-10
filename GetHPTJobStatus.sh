echo "Retrieving Status for " $1
curl -uUSERNAME "https://historical.gnip.com:443/accounts/ACCOUNTNAME/publishers/twitter/historical/track/jobs/$1.json" -X GET  | jq "." 


