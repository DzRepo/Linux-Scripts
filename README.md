# Linux-Scripts
Scripts to make working with Gnip data easier

##GetAllData.sh / GetAllData.cfg
Used to execute a Full Archive Search, following 'next' tokens to retrieve all data.  It consolidates all results into a single file as a single (potentially large) JSON object.

##HPTCleaner.sh
Decompresses and combines multiple downloaded Historical PowerTrack .gz files into a single non-compressed file.  Removes blank lines and status records.  Does not wrap individual activity records into a JSON object, so the resulting file would best be described as a "row delimited text file of individual JSON objects".
