
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


# tweak entitlement processes: inject version related info from target org
if [[ -d "${LOCAL_CURRENT_STEP_DIR}/entitlementProcesses" && "$(ls -A "${LOCAL_CURRENT_STEP_DIR}/entitlementProcesses")" ]]; then
	
	for entitlementItem in ${LOCAL_CURRENT_STEP_DIR}/entitlementProcesses/*; do
		
		echo "Processing entitlement ${entitlementItem}..."
		
		if [[ -d "$entitlementItem" || ! "${entitlementItem}" =~ ^.*\.entitlementProcess-meta\.xml$ ]]; then
			#rm -rf "$entitlementItem"
			continue;
		fi
		
		# extract entitlement name from file name and remove suffix version (if any)
		entitlementNameFromFileName="${entitlementItem##*/}";
		entitlementNameFromFileName="${entitlementNameFromFileName%%.*}";
		entitlementNameFromFileName="${entitlementNameFromFileName%_v[0-9]*}";
		
		# extract entitlement name from file content (if any)
		entitlementNameFromFileContent="$(xmlstarlet sel -t -v "//*[local-name()='EntitlementProcess']/*[local-name()='name']/text()" "$entitlementItem" || true)"
		
		entitlementName=${entitlementName:-${entitlementNameFromFileContent:-$entitlementNameFromFileName}}
		echo "Evaluated entitlement name: $entitlementName"
		
		# query info re latest entitlement version
		
		entitlementVersionInfo="$(sf data query --target-org "$PARAM_ORG_ALIAS" -q "SELECT Id, Name, NameNorm, IsActive, VersionMaster, VersionNumber, IsVersionDefault, SObjectType, StartDateField FROM SlaProcess WHERE Name='$entitlementName' ORDER BY VersionNumber DESC LIMIT 1" --json | jq -r ".result.records[0] // empty")"
		entitlementVersionMaster="$(echo "$entitlementVersionInfo" | jq -r ".VersionMaster // empty")"
		entitlementVersionNumber="$(echo "$entitlementVersionInfo" | jq -r ".VersionNumber // empty")"
		
		
		# inject version master (if any)
		if [[ ${entitlementVersionMaster:+1} ]]; then
			
			# remove existent version master (if any)
			xmlstarlet ed --inplace --delete "/*[local-name()='EntitlementProcess']/*[local-name()='versionMaster']" "$entitlementItem"
			
			# add new version master
			xmlstarlet ed --inplace -s "/*[local-name()='EntitlementProcess']" -t elem -n versionMaster -v "$entitlementVersionMaster" "$entitlementItem"
			
			
			if [[ ${entitlementVersionNumber:+1} ]]; then
				
				mv -f "$entitlementItem" "${entitlementNameFromFileName}_v${entitlementVersionNumber}.entitlementProcess-meta.xml"
				
				echo "HERE IS MODIFIED ENTITLEMENT FILE!!!"
				cat "${entitlementNameFromFileName}_v${entitlementVersionNumber}.entitlementProcess-meta.xml"
				
			fi
			
		fi
		
	done
	
fi


