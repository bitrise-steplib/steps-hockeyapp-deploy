steps-utils-json
================

Helps to retrieve a value for a key from a json formatted string. Can be easily included in other projects by adding as a submodule in SourceTree.

Uses __json__ and __prop__ variables. The simple function is named __jsonval__.

Example usage:

		json=$(/usr/bin/curl http:\\... \
			... 
			)

		echo " --- Result ---"
		echo "$json"
		echo " --------------"

		prop='install_url'
		install_url=`jsonval`
