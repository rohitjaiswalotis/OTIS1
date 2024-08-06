
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


# disable flows with inactive statuses
if [[ -d "${LOCAL_CURRENT_STEP_DIR}/tmp-flows-to-deactivate" ]]; then
	
	echo "Looking for flows to be disabled..."
	
	for flowItem in ${LOCAL_CURRENT_STEP_DIR}/tmp-flows-to-deactivate/*; do
		
		if [[ -d "$flowItem" || ! "${flowItem}" =~ ^.*\.flow-meta\.xml$ ]]; then
			continue;
		fi
		
		# parse flow status
		flowStatus=$(xmlstarlet sel -t -v "/*[local-name()='Flow']/*[local-name()='status']/text()" "$flowItem" || true)
		
		# filter only to inactive flow statuses
		if ! [[ "${flowStatus,,}" =~ ^(obsolete|draft|invaliddraft)$ ]]; then
			continue;
		fi
		
		
		mkdir -p "${LOCAL_CURRENT_STEP_DIR}/flowDefinitions"
		
		# extract flow name
		flowName="${flowItem##*/}";
		flowName="${flowName%%.*}";
		
		# generate flow definition with 0 active version to deactivate such flow altogether
		# instead of relying on default SF behaviour to just put new inactive version on top of currently active one
			cat << EOF > "${LOCAL_CURRENT_STEP_DIR}/flowDefinitions/${flowName}.flowDefinition-meta.xml"
<?xml version="1.0" encoding="UTF-8"?>
<FlowDefinition xmlns="http://soap.sforce.com/2006/04/metadata">
    <activeVersionNumber>0</activeVersionNumber>
</FlowDefinition>
EOF
		
	done
	
	
	if [[ -d "${LOCAL_CURRENT_STEP_DIR}/flowDefinitions" && "$(ls -A "${LOCAL_CURRENT_STEP_DIR}/flowDefinitions")" ]]; then
		
		echo "Generated flows definitions for deactivation:"
		ls -la "${LOCAL_CURRENT_STEP_DIR}/flowDefinitions"
		
	fi
	
	
	rm -rf "${LOCAL_CURRENT_STEP_DIR}/tmp-flows-to-deactivate"
	
fi

