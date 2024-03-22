
# parse command line arguments
while getopts ":a:x:w:" opt; do
	
	case "${opt}" in
		a)
            PARAM_ORG_ALIAS=${OPTARG}
            ;;
        x)
            PARAM_ORG2_ALIAS=${OPTARG}
            ;;
        w)
            PARAM_WORKING_DIR=${OPTARG}
            ;;
    esac
	
done


# parse params
LOCAL_CURRENT_STEP_DIR="$PARAM_WORKING_DIR"


# install xmlstarlet (if not already)
if ! command -v xmlstarlet &> /dev/null; then
	sudo apt install xmlstarlet
fi


# remove everything from objects except sharing model (including external one)
if [[ -d "${LOCAL_CURRENT_STEP_DIR}/objects" && "$(ls -A "${LOCAL_CURRENT_STEP_DIR}/objects")" ]]; then
	
	atLeastOneObjectFileWithTagsPresent=false
	
	for objectFolder in ${LOCAL_CURRENT_STEP_DIR}/objects/*; do
		
		# remove everything that is not directory or represent custom object folder
		if [[ ! -d "$objectFolder" || "$(basename "$objectFolder")" =~ ^.*__.*$ ]]; then
			rm -rf "$objectFolder"
			continue
		fi
		
		objectFileWithTagsPresent=false;
		
		# iterate over standard object items and remove everything except main object file
		for objectItem in ${objectFolder}/*; do
			
			if [[ -d "$objectItem" || ! "${objectItem}" =~ ^.*\.object-meta\.xml$ ]]; then
				rm -rf "$objectItem"
				continue;
			fi
			
			# check if target tags exist at all
			if ! xmlstarlet sel -Q -t -c "//*[local-name()='sharingModel' or local-name()='externalSharingModel']" "$objectItem"; then  
				echo "Object file $objectItem does not have target tags specified! [SKIPPED]"
				continue;
			fi
			
			objectFileWithTagsPresent=true;
			atLeastOneObjectFileWithTagsPresent=true;
			
			# delete everything except sharing model from standard object file
			xmlstarlet ed --inplace --delete "/*[local-name()='CustomObject']/*[not(local-name()='sharingModel') and not(local-name()='externalSharingModel')]" "$objectItem"
			
		done
		
		# remove object folder if no object file present
		if [[ ! "${objectFileWithTagsPresent,,}" =~ ^true$ ]]; then
			rm -rf "$objectFolder"
		fi
		
	done
	
	
	# remove objects folder if no objects files at all
	if [[ ! "${atLeastOneObjectFileWithTagsPresent,,}" =~ ^true$ ]]; then
		rm -rf "${LOCAL_CURRENT_STEP_DIR}/objects"
	fi
	
fi

