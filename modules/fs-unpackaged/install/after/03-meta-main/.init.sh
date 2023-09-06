
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


# clean up profiles from user permissions that do not exist in target org
if [[ -d "${LOCAL_CURRENT_STEP_DIR}/profiles" ]]; then
	
	echo "Reconciling profiles..."
	
	bash $RECONCILEPROFILESUTIL \
		-d "${LOCAL_CURRENT_STEP_DIR}/profiles" \
		-a "${PARAM_ORG_ALIAS}" \
		-o "${LOCAL_CURRENT_STEP_DIR}/profiles" \
		-p "$PROFILESTORECONCILE"
	
fi



# remove everything from objects except action overrides, compact layout assignment and search layouts
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
			if ! xmlstarlet sel -Q -t -c "//*[local-name()='actionOverrides' or local-name()='compactLayoutAssignment' or local-name()='searchLayouts' or local-name()='profileSearchLayouts']" "$objectItem"; then  
				echo "Object file $objectItem does not have target tags specified! [SKIPPED]"
				continue;
			fi
			
			objectFileWithTagsPresent=true;
			atLeastOneObjectFileWithTagsPresent=true;
			
			# delete everything except search layouts from standard object file
			xmlstarlet ed --inplace --delete "/*[local-name()='CustomObject']/*[not(local-name()='actionOverrides') and not(local-name()='compactLayoutAssignment') and not(local-name()='searchLayouts') and not(local-name()='profileSearchLayouts') and not(local-name()='enableFeeds') and not(local-name()='enableHistory')]" "$objectItem"
			
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


