
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


# remove everything from objects except fields with trackHistory = true
if [[ -d "${LOCAL_CURRENT_STEP_DIR}/objects" && "$(ls -A "${LOCAL_CURRENT_STEP_DIR}/objects")" ]]; then
	
	atLeastOneobjectWithTrackHistoryFieldDetected=false
	
	for objectFolder in ${LOCAL_CURRENT_STEP_DIR}/objects/*; do
		
		# remove everything that is not directory
		if [[ ! -d "$objectFolder"  ]]; then
			rm -rf "$objectFolder"
			continue
		fi
		
		objectWithTrackHistoryFieldDetected=false;
		
		# iterate over object items and remove everything except fields folder (if any)
		for objectItem in ${objectFolder}/*; do
			
			if [[ ! -d "$objectItem" || ! "${objectItem}" =~ ^.*/fields$ ]]; then
				rm -rf "$objectItem"
				continue;
			fi
			
			# iterate over fields and keep only fields files with trackHistory = true
			for fieldItem in ${objectItem}/*; do
				
				# remove everything except fields files
				if [[ -d "$fieldItem" || ! "${fieldItem}" =~ ^.*\.field-meta\.xml$ ]]; then
					rm -rf "$fieldItem"
					continue;
				fi
				
				# remove field file if not trackHistory = true
				if ! xmlstarlet sel -Q -t -c "/*[local-name()='CustomField']/*[local-name()='trackHistory'][text()='true' or text()='True' or text()='TRUE']" "$fieldItem"; then  
					rm -rf "$fieldItem"
					continue;
				fi
				
				objectWithTrackHistoryFieldDetected=true;
				atLeastOneobjectWithTrackHistoryFieldDetected=true;
				
			done
			
		done
		
		# remove object folder if no fields with trackHistory = true found at all
		if [[ ! "${objectWithTrackHistoryFieldDetected,,}" =~ ^true$ ]]; then
			rm -rf "$objectFolder"
		fi
		
	done
	
	
	# remove objects folder if no objects files at all
	if [[ ! "${atLeastOneobjectWithTrackHistoryFieldDetected,,}" =~ ^true$ ]]; then
		rm -rf "${LOCAL_CURRENT_STEP_DIR}/objects"
	fi
	
fi


