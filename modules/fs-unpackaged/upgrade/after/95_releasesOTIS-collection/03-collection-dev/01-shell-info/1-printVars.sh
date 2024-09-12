
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


echo "Defined env variables with SF_SR_VAR_ prefix:"
printenv | grep ^SF_SR_VAR_


echo "Parsed command line arguments:"
echo "PARAM_ORG_ALIAS=$PARAM_ORG_ALIAS"
echo "PARAM_ORG_URL=$PARAM_ORG_URL"
echo "PARAM_ORG_TOKEN=$PARAM_ORG_TOKEN"
echo "PARAM_ORG_API_VERSION=$PARAM_ORG_API_VERSION"
echo "PARAM_ORG2_ALIAS=$PARAM_ORG2_ALIAS"
echo "PARAM_ORG2_URL=$PARAM_ORG2_URL"
echo "PARAM_ORG2_TOKEN=$PARAM_ORG2_TOKEN"
echo "PARAM_ORG2_API_VERSION=$PARAM_ORG2_API_VERSION"
echo "PARAM_WORKING_DIR=$PARAM_WORKING_DIR"


