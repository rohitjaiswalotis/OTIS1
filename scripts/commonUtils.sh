#!/usr/bin/env bash


# get value by name from property file returning predefined one if not found
function getProperty {
   
   PROPERTY_FILE=$1;
   PROPERTY_KEY=$2;
   
   PROPERTY_DEFAULT_VALUE=${3:-""}
   
   PROPERTY_VALUE=`cat $PROPERTY_FILE | sed -e s/^#.*$//g | grep -i "^\\s*$PROPERTY_KEY\\s*=" | cut -d'=' -f2 | xargs`
   
   echo ${PROPERTY_VALUE:-$PROPERTY_DEFAULT_VALUE}
   
}


# split thousands with comma
function formatThousands {
    sed -re ' :restart ; s/([0-9])([0-9]{3})($|[^0-9])/\1,\2\3/ ; t restart '
}


# escape json
function escapeJson {
	
	# parse params
	if [ $# -ne 1 ]; then
		
		echo "Usage: $0 <textToEscape>";
		
		exit -1;
		
	fi
	
	
	# use 'jq' approach
	if [ -x "$(command -v jq)" ]; then
		
		echo "$1" | jq -R . | jq  --slurp .[] | sed -e 's/^"//' -e 's/"$//'
		
	
	# use 'python' approach
	elif [ -x "$(command -v python)" ]; then
		
		printf '%s' "$1" | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))' | sed -e 's/^"//' -e 's/"$//'
		
	
	# use manual approach
	else
		
		JSON_TOPIC_RAW="$1"
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\\/\\\\} # \ 
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\//\\\/} # / 
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\"/\\\"} # " 
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\t/\\t} # \t (tab)
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\n/\\\n} # \n (newline)
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//^M/\\\r} # \r (carriage return)
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//^L/\\\f} # \f (form feed)
		JSON_TOPIC_RAW=${JSON_TOPIC_RAW//^H/\\\b} # \b (backspace)
		
		echo "$JSON_TOPIC_RAW"
		
	fi
	
}


# encode uri param
encodeURIComponent() {
	
	awk 'BEGIN {while (y++ < 125) z[sprintf("%c", y)] = y
	while (y = substr(ARGV[1], ++j, 1))
	q = y ~ /[[:alnum:]_.!~*\47()-]/ ? q y : q sprintf("%%%02X", z[y])
	print q}' "$1"
	
}


# trim
trim() {
	
	echo -e "$(echo -e "$1" | awk '{$1=$1};1')";
	
}


# parse provided line with java properties (-Dkey1=value1 -Dkey2=value2 ...) to map (key1 => value1, key2 => value2, ...)	
function parseJavaPropertiesToMap {
	
	lineToParse="$1"
	resultMapName="${2:-javaProps}"
	
	# split each key-value pair into separate line removing '-D' along the way
	keyValueLines=$(echo "$lineToParse" | sed 's/\s\+-D/\n/g' | sed 's/^-D//g')
	
	
	eval "declare -g -A $resultMapName"
	
	
	# iterate over each key-value line, parse and populate resulting map
	while IFS= read -r keyValueLine; do
		
		key=$(echo $keyValueLine | cut -d= -f1)
		value=$(sed -e 's/^"//' -e 's/"$//' <<<$(echo $keyValueLine | cut -d= -f2-))
		
		eval "$resultMapName[$key]='$value'"
		
	done <<< "$keyValueLines"
		
}


