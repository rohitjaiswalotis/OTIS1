
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


# remove everything from objects except record types
if [[ -d "${LOCAL_CURRENT_STEP_DIR}/objects" && "$(ls -A "${LOCAL_CURRENT_STEP_DIR}/objects")" ]]; then
	
	atLeastOneobjectWithRecordTypesDetected=false
	
	for objectFolder in ${LOCAL_CURRENT_STEP_DIR}/objects/*; do
		
		# remove everything that is not directory
		if [[ ! -d "$objectFolder"  ]]; then
			rm -rf "$objectFolder"
			continue
		fi
		
		objectWithRecordTypesDetected=false;
		
		# iterate over object items and remove everything except record types folder (if any)
		for objectItem in ${objectFolder}/*; do
			
			if [[ ! -d "$objectItem" || ! "${objectItem}" =~ ^.*/recordTypes$ ]]; then
				rm -rf "$objectItem"
				continue;
			fi
			
			objectWithRecordTypesDetected=true;
			atLeastOneobjectWithRecordTypesDetected=true;
			
		done
		
		# remove object folder if no record types found at all
		if [[ ! "${objectWithRecordTypesDetected,,}" =~ ^true$ ]]; then
			rm -rf "$objectFolder"
		fi
		
	done
	
	
	# remove objects folder if no objects files at all
	if [[ ! "${atLeastOneobjectWithRecordTypesDetected,,}" =~ ^true$ ]]; then
		rm -rf "${LOCAL_CURRENT_STEP_DIR}/objects"
	fi
	
fi


