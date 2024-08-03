
# parse command line arguments
while getopts ":a:r:t:v:x:l:j:z:w:" opt; do
	
	case "${opt}" in
		a)
            PARAM_ORG_ALIAS=${OPTARG}
            ;;
        r)
            PARAM_ORG_URL=${OPTARG}
            ;;
        t)
            PARAM_ORG_TOKEN=${OPTARG}
            ;;
        v)
            PARAM_ORG_API_VERSION=${OPTARG}
            ;;
        x)
            PARAM_ORG2_ALIAS=${OPTARG}
            ;;
        l)
            PARAM_ORG2_URL=${OPTARG}
            ;;
        j)
            PARAM_ORG2_TOKEN=${OPTARG}
            ;;
        z)
            PARAM_ORG2_API_VERSION=${OPTARG}
            ;;
        w)
            PARAM_WORKING_DIR=${OPTARG}
            ;;
    esac
	
done


SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
RETURN_PROPERTIES_FILE="${SCRIPT_DIR}/.return.properties"


# delete "Additional Work" app extension (if any)
sf force data record delete --sobject AppExtension --where "AppExtensionName='WOLI Create' AppExtensionLabel='Additional Work'" --target-org "$PARAM_ORG_ALIAS" --json || true

# delete "Complete Line Item Status" app extension (if any)
sf force data record delete --sobject AppExtension --where "AppExtensionName='FS_ChangeWOLIStatus' AppExtensionLabel='Complete Line Item Status'" --target-org "$PARAM_ORG_ALIAS" --json || true

# update "Create_WO_for_Repair_Detection" app extension to align ScopedToObjectTypes
sf force data record update --sobject AppExtension --where "AppExtensionName='Create_WO_for_Repair_Detection'" --values "ScopedToObjectTypes='WorkOrder'" --target-org "$PARAM_ORG_ALIAS" --json || true

# update "Time Sheet Entry Update" app extension with installation url
sf force data record update --sobject AppExtension --where "AppExtensionName='Time Sheet Entry Update'" --values "InstallationUrl='/flow/Time_Sheet_Entry_Update'" --target-org "$PARAM_ORG_ALIAS" --json || true


