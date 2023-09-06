
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


contactDuplicateRulesAllSOQL="SELECT Id, MasterLabel, DeveloperName, NamespacePrefix, SObjectType, IsActive FROM DuplicateRule WHERE SObjectType='Contact' ORDER BY CreatedDate ASC";
contactDuplicateRuleDevName="Contact_Duplicate_Rule"


# query all Contact duplicate rules
CONTACT_DUPLICATE_RULES_RESPONSE=$(sf data query --target-org "$PARAM_ORG_ALIAS" -q "$contactDuplicateRulesAllSOQL" --json);

# search Contact duplicate rule by developer name in fetched array of records and get its index (if any), otherwise array length is returned 
contactDuplicateRuleIndex=$(echo -n "$CONTACT_DUPLICATE_RULES_RESPONSE" | jq -r ".result.records | map(.DeveloperName == \"$contactDuplicateRuleDevName\") | index(true) // length");
contactDuplicateRuleIndex=$(( $contactDuplicateRuleIndex + 1 ))


# return results to caller
echo "SF_SR_VAR_CONTACT_DUPLICATE_RULE_ORDER=$contactDuplicateRuleIndex" >> ${SCRIPT_DIR}/.return.properties


