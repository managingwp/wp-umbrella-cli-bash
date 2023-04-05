#!/bin/bash

# ======================
# -- Variables
# ======================
API_URL="https://api.wp-umbrella.com/v2"

# ======================
# Functions
# ======================

# -- usage
function usage () {
	USAGE=\
"./wp-umbrella.sh <command>
  Commands:
    me                        - List account profile
    projects                  - List projects
    project <projectid>       - List project details
    backups <projectid>       - List backup details for project
"
	echo "$USAGE"
}

# -- api
function api () {
	ENDPOINT="$1"
	URL="${API_URL}/${ENDPOINT}"
	API_CURL=$(curl -s --request GET "${URL}" --header 'Authorization: Bearer '""$API_TOKEN""' ')	
	RESULT=$(echo ${API_CURL})
	if [[ $(echo $RESULT | jq -r '.code') != "success" ]]; then
	    echo "API Failure - "
        echo $RESULT | jq
    else
    	#echo "Success"
    	echo $RESULT | jq
    fi
}

# -- list_projects
function list_projects () {
	JSON=$1
	count=1
	OUTPUT="ID,Name,URL\n"
	OUTPUT+=$(echo "$JSON" | jq -r '.data[] | "\(.id),\(.name),\(.base_url)"')
	FINAL_OUTPUT=$(echo -e "$OUTPUT" | column -t -s ',')
	count=1
	while read -r line; do
		echo "$line"
		if [[ $count -eq 1 ]]; then
			echo "------------------------------------------------------------"
 		fi
		count=$((count + 1))
	done <<< "$FINAL_OUTPUT"
    if [[ $RAW_JSON == "1" ]]; then
        echo $JSON | jq
    fi
}

function getProject () {
	JSON=$1
	SITE=$2
	echo "$JSON" | jq -r '.data[] | select( .id == 9509 )'
}

function get_backup () {
	# --------------
	#  "id": 130490,
	#  "is_scheduled": true,
	#  "created_at": "2022-09-13T07:01:06.505Z",
	#  "wordpress_version": "6.0.2",
	#  "count_plugin": 0,
	#  "count_attachment": "-",
	#  "count_post": "-",
	#  "theme": "- "
	# --------------

	JSON=$1
    SITE=$2
    echo "Getting backups for site $2"
    OUTPUT="ID,Scheduled,Created At,WordPress Version,Plugin,Attach,Post,Theme\n"
    OUTPUT+=$(echo "$JSON" | jq -r '.data[] | "\(.id),\(.is_scheduled),\(.created_at),\(.wordpress_version),\(.count_plugin),\(.count_attachment),\(.count_post),\(.theme)"')
    FINAL_OUTPUT=$(echo -e "$OUTPUT" | column -t -s ',')
    count=1
    while read -r line; do
        echo "$line"
        if [[ $count -eq 1 ]]; then
            echo "------------------------------------------------------------"
        fi
        count=$((count + 1))
    done <<< "$FINAL_OUTPUT"
}

# -- pre_flight
pre_flight () {
	if [[ -n $WP_UMBRELLA_APIKEY ]]; then
	    API_TOKEN="$WP_UMBRELLA_APIKEY"
	else
		usage
	    echo "** Error: API Token not available, please set the API Key via 'export \$WP_UMBRELLA_TOKEN'"
	    exit
	fi
	API_URL="https://api.wp-umbrella.com/v2"
}

####################################
# ----------------------------------
####################################

pre_flight

# -- Arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    # TODO implement debug.
    -d|--debug)
    DEBUG="1"
    shift # past argument        
    ;;
    -r|--raw-json)
    RAW_JSON="1"
    shift # past argument    
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


# -- main loop
if [[ -z $1 ]]; then
	usage
	exit 1
#### -- me
elif [[ $1 == "me" ]]; then
	api me
#### -- projects
elif [[ $1 == "projects" ]]; then
	JSON=$(api projects)
	list_projects "$JSON"
#### -- project
elif [[ $1 == "project" ]]; then
	if [[ -z $2 ]]; then
		echo "Need project ID"
		exit 1
	else 
		JSON=$(api projects)
		getProject "$JSON" $2
	fi
#### -- backups
elif [[ $1 == "backups" ]]; then
	if [[ -z $2 ]]; then
        echo "Need project ID"
        exit 1
    else
        JSON=$(api projects/${2}/backups)
        get_backup "$JSON" $2
    fi
else
	usage
	exit 1
fi