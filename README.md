# Linux-Scripts
Scripts to make working with Gnip data easier

##FullArchiveSearch
Used to execute a query against Gnip's [Full Archive Search](http://support.gnip.com/apis/search_full_archive_api/).

  * Follows 'next' tokens to retrieve all data.
  * Consolidates all results into a single file as a single (potentially large) JSON object.
  * Can be used to retreive either counts or data
  * Requires [curl](https://curl.haxx.se), [sed](http://www.grymoire.com/Unix/Sed.html), and [jq](https://stedolan.github.io/jq/)
*  All parameters currently are set in [FullArchiveSearch.cfg](FullArchiveSearch.cfg)  - no command line parameters.

##HPTCleaner
Decompresses and combines multiple downloaded Historical PowerTrack .gz files into a single non-compressed file.

  * Removes blank lines and status records.
  * Does not wrap individual activity records into a JSON object, so the resulting file would best be described as a *"line delimited text file of individual JSON objects"*.
  * Supports a large number of files
  * Creates a file named 'filtered.json'
  * Accepts a command line parameter of a filter describing colection of files to decompress/combine
     * Example:  ./HPTCleaner Activities-Test*.gz

## Historical PowerTrack mangagement scripts

* CreateHPTJob.sh
* GetHPTJobs.sh
* GetHPTJobStatus.sh
* AcceptHPTJob.sh
* RejectHPTJob.sh
 
All of the above are simple bash scripts to help manage HPT jobs.
I've not found it feasible or necessary to write a pure bash script to download the individual HPT jobs.  For that there are either tools [here](http://support.gnip.com/code/historical_powertrack.html) and in my Python repository [here](https://github.com/GnipDz/Python) or PowerShell repository [here](https://github.com/GnipDz/Powershell)

