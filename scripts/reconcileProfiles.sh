#!/usr/bin/env bash

# enable exit on error
set -e


# const

ENABLE_PROFILES_RECONCILIATION="${ENABLEPROFILESRECONCILIATION:-true}"



########################## FUNCTIONS (BEGIN)

function usage() { 
    echo "Usage: $0 -d <profilesDir> -a <orgAlias> -p <profiles> -o <outputDir>" 1>&2;
}


########################## FUNCTIONS (END)


########################## MAIN (BEGIN)


# parse command line arguments
while getopts ":d:a:p:o:h" opt; do
    
    case "${opt}" in
        d)
            PARAM_PROFILES_DIR="${OPTARG}"
            ;;
        a)
            PARAM_ORG_ALIAS=${OPTARG}
            ;;
        p)
			PARAM_PROFILES="${OPTARG}"
            ;;
        o)
            PARAM_OUTPUT_DIR="${OPTARG}"
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    
done


# early exit: profiles reconciliation is disabled
if [[ ! "${ENABLE_PROFILES_RECONCILIATION,,}" =~ ^true$ ]]; then
	echo "WARN: Profiles reconciliation is disabled!"
	exit 0 # returning success since nothing to reconcile here
fi


# early exit: no profiles directory available
if [[ ! -d "$PARAM_PROFILES_DIR" ]]; then
	echo "WARN: Incoming profiles directory '$PARAM_PROFILES_DIR' does not exist!"
	exit 0 # returning success since nothing to reconcile here
fi


LOCAL_WORKING_DIR=$(mktemp -d);
mkdir -p $LOCAL_WORKING_DIR/userPermissions
mkdir -p $LOCAL_WORKING_DIR/reconciledUserPermissions
mkdir -p $LOCAL_WORKING_DIR/everythingElse
mkdir -p $LOCAL_WORKING_DIR/result


IFS=',' read -r -a LOCAL_PROFILES_NAMES <<< "$PARAM_PROFILES"

LOCAL_PROFILES_LIST=""


# install xmlstarlet (if not already)
if ! command -v xmlstarlet &> /dev/null; then
	sudo apt install xmlstarlet
fi

# install sfpowerkit (if not already)
(sf plugins | grep -i "sfpowerkit") || (echo "y" | sf plugins install sfpowerkit@latest)


# iterate over profile names and split into user permissions vs everything else
for LOCAL_PROFILE_NAME in "${LOCAL_PROFILES_NAMES[@]}"; do
    
	# trim
	LOCAL_PROFILE_NAME=$(echo "$LOCAL_PROFILE_NAME" | xargs);
	
	LOCAL_PROFILE_FILENAME="${LOCAL_PROFILE_NAME}.profile-meta.xml"
	LOCAL_PROFILE_FILEPATH="${PARAM_PROFILES_DIR}/${LOCAL_PROFILE_FILENAME}"
	
	# skip non-existent profiles
	if [[ ! -f "$LOCAL_PROFILE_FILEPATH" ]]; then
		echo "Profile file $LOCAL_PROFILE_FILEPATH does not exist! [SKIPPED]"
		continue
	fi
	
	# check if user permissions exist at all
	if ! xmlstarlet sel -Q -t -c "//*[local-name()='userPermissions']" "$LOCAL_PROFILE_FILEPATH"; then  
		echo "Profile file $LOCAL_PROFILE_FILEPATH does not have user permissions specified! [SKIPPED]"
		continue;
	fi
	
	# delete everything except user permissions and some required tags (e.g. userLicense), then save as separate file
    xmlstarlet ed --delete "/*[local-name()='Profile']/*[not(local-name()='userPermissions') and not(local-name()='userLicense') and not(local-name()='custom') and not(local-name()='description') ]" "$LOCAL_PROFILE_FILEPATH" > "${LOCAL_WORKING_DIR}/userPermissions/${LOCAL_PROFILE_FILENAME}"
	
	# delete userpermissions and save as separate file
	xmlstarlet ed --delete "//*[local-name()='userPermissions']" "$LOCAL_PROFILE_FILEPATH" > "${LOCAL_WORKING_DIR}/everythingElse/${LOCAL_PROFILE_FILENAME}"
    
	# collect profile names
    if [[ ${LOCAL_PROFILES_LIST:+1} ]]; then
        LOCAL_PROFILES_LIST="$LOCAL_PROFILES_LIST,${LOCAL_PROFILE_NAME}"
	else
	    LOCAL_PROFILES_LIST="${LOCAL_PROFILE_NAME}"
	fi
    
done


# actually reconcile user permissions against org
if [[ ${LOCAL_PROFILES_LIST:+1} ]]; then
	
	sf sfpowerkit:source:profile:reconcile -u "${PARAM_ORG_ALIAS}" \
		--folder ${LOCAL_WORKING_DIR}/userPermissions \
		-d ${LOCAL_WORKING_DIR}/reconciledUserPermissions \
		--profilelist="$LOCAL_PROFILES_LIST"
	
fi


# iterate over profile names and merge reconciled permissions with rest of the profiles
for LOCAL_PROFILE_NAME in "${LOCAL_PROFILES_NAMES[@]}"; do
	
	# trim
	LOCAL_PROFILE_NAME=$(echo "$LOCAL_PROFILE_NAME" | xargs);
	
	LOCAL_PROFILE_FILENAME="${LOCAL_PROFILE_NAME}.profile-meta.xml"
	LOCAL_PROFILE_FILEPATH="${PARAM_PROFILES_DIR}/${LOCAL_PROFILE_FILENAME}"
	
	# skip non-existent profiles
	if [[ ! -f "$LOCAL_PROFILE_FILEPATH" || ! -f "${LOCAL_WORKING_DIR}/everythingElse/${LOCAL_PROFILE_FILENAME}" || ! -f "${LOCAL_WORKING_DIR}/reconciledUserPermissions/${LOCAL_PROFILE_FILENAME}" ]]; then
		continue
	fi
	
	# remove closing tag: </Profile>
	sed '/<\/Profile>/d' "${LOCAL_WORKING_DIR}/everythingElse/${LOCAL_PROFILE_FILENAME}" > "${LOCAL_WORKING_DIR}/result/${LOCAL_PROFILE_FILENAME}"
	
	# extract reconciled user permissions and append into result file
	grep -Pzo "(?s)<userPermissions>.*</userPermissions>" "${LOCAL_WORKING_DIR}/reconciledUserPermissions/${LOCAL_PROFILE_FILENAME}" >> "${LOCAL_WORKING_DIR}/result/${LOCAL_PROFILE_FILENAME}"
	
	# put back closing tag: </Profile>
	echo -n "</Profile>" >> "${LOCAL_WORKING_DIR}/result/${LOCAL_PROFILE_FILENAME}"
	
	# remove 0 byte, i.e. 0x0 char (if any)
	sed -i 's/\x0//g' "${LOCAL_WORKING_DIR}/result/${LOCAL_PROFILE_FILENAME}"
	
done


# copy reconciled profiles into result dir (if any)
if [[ ${LOCAL_PROFILES_LIST:+1} ]]; then
	cp -rf ${LOCAL_WORKING_DIR}/result/* ${PARAM_OUTPUT_DIR} || true
fi


# clean up
rm -rf $LOCAL_WORKING_DIR || true


########################## MAIN (END)

