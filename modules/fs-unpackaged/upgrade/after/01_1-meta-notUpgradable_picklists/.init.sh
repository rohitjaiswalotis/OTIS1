
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


# remove everything from objects except picklist fields
if [[ -d "${LOCAL_CURRENT_STEP_DIR}/objects" && "$(ls -A "${LOCAL_CURRENT_STEP_DIR}/objects")" ]]; then
	
	atLeastOneobjectWithPicklistFieldDetected=false
	
	for objectFolder in ${LOCAL_CURRENT_STEP_DIR}/objects/*; do
		
		# remove everything that is not directory
		if [[ ! -d "$objectFolder"  ]]; then
			rm -rf "$objectFolder"
			continue
		fi
		
		objectWithPicklistFieldDetected=false;
		
		# iterate over object items and remove everything except fields folder (if any)
		for objectItem in ${objectFolder}/*; do
			
			if [[ ! -d "$objectItem" || ! "${objectItem}" =~ ^.*/fields$ ]]; then
				rm -rf "$objectItem"
				continue;
			fi
			
			# iterate over fields and keep only picklists files (single or multi select)
			for fieldItem in ${objectItem}/*; do
				
				# remove everything except fields files
				if [[ -d "$fieldItem" || ! "${fieldItem}" =~ ^.*\.field-meta\.xml$ ]]; then
					rm -rf "$fieldItem"
					continue;
				fi
				
				# remove field file if not picklist
				if ! xmlstarlet sel -Q -t -c "/*[local-name()='CustomField']/*[local-name()='type'][text()='Picklist' or text()='picklist' or text()='PICKLIST' or text()='MultiselectPicklist' or text()='MultiSelectPicklist' or text()='multiSelectPicklist' or text()='multiselectPicklist' or text()='multiselectpicklist' or text()='MULTISELECTPICKLIST']" "$fieldItem"; then  
					rm -rf "$fieldItem"
					continue;
				fi
				
				objectWithPicklistFieldDetected=true;
				atLeastOneobjectWithPicklistFieldDetected=true;
				
			done
			
		done
		
		# remove object folder if no picklist fields found at all
		if [[ ! "${objectWithPicklistFieldDetected,,}" =~ ^true$ ]]; then
			rm -rf "$objectFolder"
		fi
		
	done
	
	
	# remove objects folder if no objects files at all
	if [[ ! "${atLeastOneobjectWithPicklistFieldDetected,,}" =~ ^true$ ]]; then
		rm -rf "${LOCAL_CURRENT_STEP_DIR}/objects"
	fi
	
fi


