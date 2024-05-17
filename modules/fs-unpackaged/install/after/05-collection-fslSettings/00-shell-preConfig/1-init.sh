
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

woServiceDocTemplateName="Service_Document_Template_for_WO"
woSummaryReportDocTemplateName="Summary_Report_on_WO"

getServiceDocTemplatesSOQL="SELECT Id, DeveloperName, MasterLabel, NamespacePrefix, ParentFlexiPage, Type FROM FlexiPage WHERE Type = 'ServiceDocument' AND DeveloperName IN ( '$woServiceDocTemplateName', '$woSummaryReportDocTemplateName' )";


# query service document templates
serviceDocTemplatesResponse=$(sf data query --use-tooling-api --target-org "$PARAM_ORG_ALIAS" -q "$getServiceDocTemplatesSOQL" --json);


# get specific template ids from response (empty if not found)
woServiceDocTemplateId=$(echo -n "$serviceDocTemplatesResponse" | jq -r ".result.records[] | select(.DeveloperName == \"$woServiceDocTemplateName\") | .Id // empty");
woSummaryReportDocTemplateId=$(echo -n "$serviceDocTemplatesResponse" | jq -r ".result.records[] | select(.DeveloperName == \"$woSummaryReportDocTemplateName\") | .Id // empty");


echo "Parsed id for $woServiceDocTemplateName service doc: $woServiceDocTemplateId"
echo "Parsed id for $woSummaryReportDocTemplateName service doc: $woSummaryReportDocTemplateId"


# return results
echo "SF_SR_VAR_WO_SERVICE_DOC_TEMPLATE_ID=$woServiceDocTemplateId" >> "$RETURN_PROPERTIES_FILE"
echo "SF_SR_VAR_WO_SUMMARY_REPORT_DOC_TEMPLATE_ID=$woSummaryReportDocTemplateId" >> "$RETURN_PROPERTIES_FILE"


