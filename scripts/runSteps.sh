#!/usr/bin/env bash

# enable exit on error
set -e


# const

JSFORCE_RUNNER_VERSION="${JSFORCERUNNERVERSION:-latest}";
POSTMAN_RUNNER_VERSION="${POSTMANRUNNERVERSION:-latest}";
SFDMU_PLUGIN_VERSION="${SFDMUVERSION:-latest}";

SF_API_VERSION="${SFAPIVERSION:-61.0}";

STEP_INDEX_REGEX="[0-9][0-9a-zA-Z_#@:.]*";

STEP_MAX_RETRY_ATTEMPTS=${SCRIPTSTEPMAXRETRYATTEMPTS:-2};
STEP_RETRY_DELAY=${SCRIPTSTEPRETRYDELAY:-10};

DEBUG_MODE=${DEBUG_MODE:-0}

STEPS_RUNNER_UTIL=$0;


########################## FUNCTIONS (BEGIN)

warn() {
    echo "$@" 1>&2
}


error() {
    echo "$@" 1>&2
}


fail() {
    error "$@"
    exit -1
}


function usage() { 
    echo "Usage: $0 -d <scriptDir> -a <orgAlis> -w <workingDir> [-u <username>] [-p <password>] [-r <url>] [-n <stepName>] [-o <outputDir>]" 1>&2;
}


# get value by name from property file returning predefined one if not found
function getProperty {
    
    local PROPERTY_FILE=$1;
    local PROPERTY_KEY=$2;
    
    local PROPERTY_DEFAULT_VALUE=${3:-""}
    
    local PROPERTY_VALUE=`cat $PROPERTY_FILE | sed -e s/^#.*$//g | grep -i "^\\s*$PROPERTY_KEY\\s*=" | cut -d'=' -f2- | xargs`
    
    echo ${PROPERTY_VALUE:-$PROPERTY_DEFAULT_VALUE}
    
}


# define variables from property file
function defineVarsFromProps {
    
    local PROPERTY_FILE=$1;
    
    while read line; do
        echo export $line
        eval export $line
    done <<< "$(cat ${PROPERTY_FILE} | sed -e s/^#.*$//g | grep -v "^\s*$" | sed -e s/\\s*=\\s*/=/ )" # remove comments/empty lines, trim spaces around '='
    
}


# process data commands from property file
function processDataCommands {
    
    local PROPERTY_FILE=$1;
    local BASE_PATH=$2;
    
    
    # copy data
    
    local dataCopies=( $(getProperty $PROPERTY_FILE "data.copy" "") )
    
    for dataCopy in "${dataCopies[@]}"; do
        
        local dataSource="$(echo $dataCopy | cut -d ":" -f1)"
		eval dataSource="\"$dataSource\"";
		local dataSourcePath="${dataSource%/*\**}"
		
        local dataDest="$(echo $dataCopy | cut -d ":" -f2)"
		eval dataDest="\"$dataDest\"";
        
        if [[ -e "$dataSourcePath" ]]; then
            echo "Copying additional data into current step..."
            echo cp -rf "${dataSource}" "${BASE_PATH}/${dataDest}"
            cp -rf ${dataSource} ${BASE_PATH}/${dataDest}
        else
            echo "WARNING: Data source '${dataSourcePath}' for copy command does not exist."
        fi
        
    done
    
    
    # move data
    
    local dataMoves=( $(getProperty $PROPERTY_FILE "data.move" "") )
    
    for dataMove in "${dataMoves[@]}"; do
        
        local dataSource="$(echo $dataMove | cut -d ":" -f1)"
		eval dataSource="\"$dataSource\"";
		local dataSourcePath="${dataSource%/*\**}"
		
        local dataDest="$(echo $dataMove | cut -d ":" -f2)"
		eval dataDest="\"$dataDest\"";
        
        if [[ -e "$dataSourcePath" ]]; then
            echo "Moving additional data into current step..."
            echo mv -f "${dataSource}" "${BASE_PATH}/${dataDest}"
            mv -f ${dataSource} ${BASE_PATH}/${dataDest}
        else
            echo "WARNING: Data source '${dataSourcePath}' for move command does not exist."
        fi
        
    done
	
    
    # remove data
    
    local dataRemoves=( $(getProperty $PROPERTY_FILE "data.remove" "") )
    
    for dataRemove in "${dataRemoves[@]}"; do
        
		local dataSource="$dataRemove"
		eval dataSource="\"$dataSource\"";
		local dataSourcePath="${dataSource%/*\**}"
		
        if [[ -e "$dataSourcePath" ]]; then
            echo "Removing additional data into current step..."
            echo rm -rf "${dataSource}"
            rm -rf ${dataSource}
        else
            echo "WARNING: Data source '${dataSourcePath}' for remove command does not exist."
        fi
        
    done
    
}


# resolve/replace dynamic variables inside files
function resolveDynamicEnvVarsInFiles {
    
    local BASE_PATH=$1;
    
    if [[ "${!SF_SR_VAR_*}" != "" ]]; then
        
        SAVEIFS=$IFS
        IFS=$(echo -en "\n\b")
        
        for artifact in $(find ${BASE_PATH} -type f -not -path '*/\.*' -exec grep -Il '.' {} \;); do
            
            # resolve in file content
            echo "Processing artifact $artifact ..."
            envsubst "$(printf '${%s} ' ${!SF_SR_VAR_*})"  <"$artifact" >"$artifact.tmp" && mv -f "$artifact.tmp" "$artifact"
            #echo "Artifact after processing:"; cat "$artifact"
            
            # resolve in file name
            local artifactResolvedName=$(echo -n "$artifact" | envsubst "$(printf '${%s} ' ${!SF_SR_VAR_*})");
            mv -f "$artifact" "$artifactResolvedName" > /dev/null 2>&1 && echo "Resolved dynamic vars in artifact name: $artifact -> $artifactResolvedName" || true
            
        done;
        
        IFS=$SAVEIFS
        
    fi
    
}


# get sf org details
function getOrgDetails {
	
	local sfOrgAlias="$1";
	
	local retryAttempts=${2:-$STEP_MAX_RETRY_ATTEMPTS}
	local retryDelay=${3:-$STEP_RETRY_DELAY}
	
	local retryCounter=0;
	
	local backupErrorExitMode;
	
	# backup current error switcher value and disable exit on error
	[ -o errexit ] && backupErrorExitMode='set -e' || backupErrorExitMode='set +e'; set +e
	
	
	while true; do 
		
		sfOrgDetails=$(sf org display -o "$sfOrgAlias" --verbose --json | jq -r ".result // empty" || true);
		sfOrgId=$(echo "$sfOrgDetails" | jq -r '.id // empty');
		
		# success
		if [[ ${sfOrgId:+1} ]]; then
			break;
			
		# failure
		else
			
			warn "ERROR: Get org details for alias '$sfOrgAlias'!"
			
			# retry if not run out of attempts
			if [[ $retryCounter -lt $retryAttempts ]]; then
				
				retryCounter=$(( $retryCounter + 1 ));
				warn "Retrying get org details after failure in ${retryDelay} seconds (attempt ${retryCounter}/${retryAttempts})..."
				sleep $retryDelay;
				
			# run out of retry attempts: exit with error code
			else
				
				fail "ERROR: Run out of retry attempts (max=${retryAttempts})"
				
			fi
			
		fi
		
	done
	
	# restore 'exit on error' flag state
	eval "$backupErrorExitMode"
	
	# print result back to be parsed by caller
	echo "$sfOrgDetails"
	
}


# get advanced sf org details (query via soql to grap org name, instance name, namespace, 'is sandbox' etc.)
function getAdvancedOrgDetails {
	
	local sfOrgAlias="$1";
	
	local retryAttempts=${2:-$STEP_MAX_RETRY_ATTEMPTS}
	local retryDelay=${3:-$STEP_RETRY_DELAY}
	
	local retryCounter=0;
	
	local backupErrorExitMode;
	
	# backup current error switcher value and disable exit on error
	[ -o errexit ] && backupErrorExitMode='set -e' || backupErrorExitMode='set +e'; set +e
	
	
	while true; do 
		
		sfOrgDetails=$(sf data query -o "$sfOrgAlias" -q "SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization LIMIT 1" --json | jq -r ".result.records[0] // empty" || true);
		sfOrgId=$(echo "$sfOrgDetails" | jq -r '.Id // empty');
		
		# success
		if [[ ${sfOrgId:+1} ]]; then
			break;
			
		# failure
		else
			
			warn "ERROR: Get advanced org details for alias '$sfOrgAlias'!"
			
			# retry if not run out of attempts
			if [[ $retryCounter -lt $retryAttempts ]]; then
				
				retryCounter=$(( $retryCounter + 1 ));
				warn "Retrying get advanced org details after failure in ${retryDelay} seconds (attempt ${retryCounter}/${retryAttempts})..."
				sleep $retryDelay;
				
			# run out of retry attempts: exit with error code
			else
				
				fail "ERROR: Run out of retry attempts (max=${retryAttempts})"
				
			fi
			
		fi
		
	done
	
	# restore 'exit on error' flag state
	eval "$backupErrorExitMode"
	
	# print result back to be parsed by caller
	echo "$sfOrgDetails"
	
}


########################## FUNCTIONS (END)


########################## MAIN (BEGIN)


# parse command line arguments
while getopts ":d:a:w:u:p:r:n:o:x:e:t:l:c:h" opt; do
    
    case "${opt}" in
        d)
            PARAM_STEPS_DIR=${OPTARG}
            ;;
        a)
            PARAM_ORG_ALIAS=${OPTARG}
            ;;
        w)
            PARAM_WORKING_DIR=${OPTARG}
            ;;
        u)
            PARAM_ORG_USERNAME=${OPTARG}
            ;;
        p)
            PARAM_ORG_PASSWORD="${OPTARG}"
            ;;
        r)
            PARAM_ORG_URL=${OPTARG}
            ;;
        n)
            PARAM_STEP_TO_RUN="${OPTARG}"
            ;;
        o)
            PARAM_SCRIPT_SANDBOX_DIR=${OPTARG}
            ;;
        x)
            PARAM_ORG2_ALIAS=${OPTARG}
            ;;
        e)
            PARAM_ORG2_USERNAME=${OPTARG}
            ;;
        t)
            PARAM_ORG2_PASSWORD="${OPTARG}"
            ;;
        l)
            PARAM_ORG2_URL=${OPTARG}
            ;;
        c)
            PARAM_SCRIPT_PARAMS_FILE=${OPTARG}
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    
done


if [[ ! -d "${PARAM_STEPS_DIR}" ]]; then
    echo "WARNING: Steps directory '${PARAM_STEPS_DIR}' does not exist!"
    exit 0;
fi


# setting defaults
PARAM_STEP_TO_RUN="${PARAM_STEP_TO_RUN:-*}"
PARAM_SCRIPT_SANDBOX_DIR="${PARAM_SCRIPT_SANDBOX_DIR:-$(mktemp -d)}"
PARAM_WORKING_DIR="${PARAM_WORKING_DIR:-$(pwd)}"

groovyClassPath="${PARAM_WORKING_DIR}/lib/*:${PARAM_WORKING_DIR}/scripts/groovy"


echo "Incoming directory with steps: ${PARAM_STEPS_DIR}"
echo "Sandbox directory: ${PARAM_SCRIPT_SANDBOX_DIR}"

echo "Current script structure:"
ls -la $PARAM_STEPS_DIR


cp -rf ${PARAM_STEPS_DIR}/. ${PARAM_SCRIPT_SANDBOX_DIR}/ || true # to suppress error when source and dest dirs are actually the same, i.e. in-place transformation/execution


# grab info re orgs and define as global variables

if [[ ${PARAM_ORG_ALIAS:+1} ]]; then
	
	sfOrgDetails=$(getOrgDetails "$PARAM_ORG_ALIAS");
	
	export SF_SR_VAR_SYSTEM_ORG_ID="${SF_SR_VAR_SYSTEM_ORG_ID:-"$(echo "$sfOrgDetails" | jq -r '.id // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_ID_18="${SF_SR_VAR_SYSTEM_ORG_ID_18:-${SF_SR_VAR_SYSTEM_ORG_ID:0:18}}"
	export SF_SR_VAR_SYSTEM_ORG_ID_15="${SF_SR_VAR_SYSTEM_ORG_ID_15:-${SF_SR_VAR_SYSTEM_ORG_ID:0:15}}"
	
	export SF_SR_VAR_SYSTEM_ORG_INSTANCE_URL="${SF_SR_VAR_SYSTEM_ORG_INSTANCE_URL:-"$(echo "$sfOrgDetails" | jq -r '.instanceUrl // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_DOMAIN="${SF_SR_VAR_SYSTEM_ORG_DOMAIN:-"$(echo "$SF_SR_VAR_SYSTEM_ORG_INSTANCE_URL" | cut -d'/' -f3)"}";
	
	export SF_SR_VAR_SYSTEM_ORG_USERNAME="${SF_SR_VAR_SYSTEM_ORG_USERNAME:-"$(echo "$sfOrgDetails" | jq -r '.username // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_API_VERSION="${SF_SR_VAR_SYSTEM_ORG_API_VERSION:-"$(echo "$sfOrgDetails" | jq -r '.apiVersion // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_API_VERSION_MAJOR="${SF_SR_VAR_SYSTEM_ORG_API_VERSION_MAJOR:-"$(echo "$SF_SR_VAR_SYSTEM_ORG_API_VERSION" | cut -d "." -f1)"}";
	
	
	sfAdvancedOrgDetails=$(getAdvancedOrgDetails "$PARAM_ORG_ALIAS");
	
	export SF_SR_VAR_SYSTEM_ORG_NAME="${SF_SR_VAR_SYSTEM_ORG_NAME:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.Name // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_INSTANCE_NAME="${SF_SR_VAR_SYSTEM_ORG_INSTANCE_NAME:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.InstanceName // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_IS_SANDBOX="${SF_SR_VAR_SYSTEM_ORG_IS_SANDBOX:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.IsSandbox // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_NAMESPACE="${SF_SR_VAR_SYSTEM_ORG_NAMESPACE:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.NamespacePrefix // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_EDITION="${SF_SR_VAR_SYSTEM_ORG_EDITION:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.OrganizationType // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG_TRIAL_EXPIRATION_DATE="${SF_SR_VAR_SYSTEM_ORG_TRIAL_EXPIRATION_DATE:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.TrialExpirationDate // empty')"}";
	
	
	# check if scratch org
	if [[ ! ${SF_SR_VAR_SYSTEM_ORG_IS_SCRATCH:+1} && "${SF_SR_VAR_SYSTEM_ORG_IS_SANDBOX,,}" =~ ^true$ && ${SF_SR_VAR_SYSTEM_ORG_TRIAL_EXPIRATION_DATE:+1} ]]; then
		export SF_SR_VAR_SYSTEM_ORG_IS_SCRATCH=true
		export SF_SR_VAR_SYSTEM_ORG_IS_SANDBOX=false
	else
		export SF_SR_VAR_SYSTEM_ORG_IS_SCRATCH=false
	fi
	
	
	# parse sandbox name from url
	if [[ "${SF_SR_VAR_SYSTEM_ORG_IS_SANDBOX,,}" =~ ^true$ && ! ${SF_SR_VAR_SYSTEM_ORG_SANDBOX_NAME:+1} ]]; then
		
		SF_SR_VAR_SYSTEM_ORG_SANDBOX_NAME="${SF_SR_VAR_SYSTEM_ORG_INSTANCE_URL##*--}"
		export SF_SR_VAR_SYSTEM_ORG_SANDBOX_NAME="${SF_SR_VAR_SYSTEM_ORG_SANDBOX_NAME%%.*}"
		
	fi
	
	
	unset sfOrgDetails
	unset sfAdvancedOrgDetails
	
fi


if [[ ${PARAM_ORG2_ALIAS:+1} ]]; then
	
	sfOrgDetails=$(getOrgDetails "$PARAM_ORG2_ALIAS");
	
	export SF_SR_VAR_SYSTEM_ORG2_ID="${SF_SR_VAR_SYSTEM_ORG2_ID:-"$(echo "$sfOrgDetails" | jq -r '.id // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_ID_18="${SF_SR_VAR_SYSTEM_ORG2_ID_18:-${SF_SR_VAR_SYSTEM_ORG2_ID:0:18}}"
	export SF_SR_VAR_SYSTEM_ORG2_ID_15="${SF_SR_VAR_SYSTEM_ORG2_ID_15:-${SF_SR_VAR_SYSTEM_ORG2_ID:0:15}}"
	
	export SF_SR_VAR_SYSTEM_ORG2_INSTANCE_URL="${SF_SR_VAR_SYSTEM_ORG2_INSTANCE_URL:-"$(echo "$sfOrgDetails" | jq -r '.instanceUrl // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_DOMAIN="${SF_SR_VAR_SYSTEM_ORG2_DOMAIN:-"$(echo "$SF_SR_VAR_SYSTEM_ORG2_INSTANCE_URL" | cut -d'/' -f3)"}";
	
	export SF_SR_VAR_SYSTEM_ORG2_USERNAME="${SF_SR_VAR_SYSTEM_ORG2_USERNAME:-"$(echo "$sfOrgDetails" | jq -r '.username // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_API_VERSION="${SF_SR_VAR_SYSTEM_ORG2_API_VERSION:-"$(echo "$sfOrgDetails" | jq -r '.apiVersion // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_API_VERSION_MAJOR="${SF_SR_VAR_SYSTEM_ORG2_API_VERSION_MAJOR:-"$(echo "$SF_SR_VAR_SYSTEM_ORG2_API_VERSION" | cut -d "." -f1)"}";
	
	
	sfAdvancedOrgDetails=$(getAdvancedOrgDetails "$PARAM_ORG2_ALIAS");
	
	export SF_SR_VAR_SYSTEM_ORG2_NAME="${SF_SR_VAR_SYSTEM_ORG2_NAME:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.Name // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_INSTANCE_NAME="${SF_SR_VAR_SYSTEM_ORG2_INSTANCE_NAME:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.InstanceName // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_IS_SANDBOX="${SF_SR_VAR_SYSTEM_ORG2_IS_SANDBOX:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.IsSandbox // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_NAMESPACE="${SF_SR_VAR_SYSTEM_ORG2_NAMESPACE:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.NamespacePrefix // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_EDITION="${SF_SR_VAR_SYSTEM_ORG2_EDITION:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.OrganizationType // empty')"}";
	export SF_SR_VAR_SYSTEM_ORG2_TRIAL_EXPIRATION_DATE="${SF_SR_VAR_SYSTEM_ORG2_TRIAL_EXPIRATION_DATE:-"$(echo "$sfAdvancedOrgDetails" | jq -r '.TrialExpirationDate // empty')"}";
	
	
	# check if scratch org
	if [[ ! ${SF_SR_VAR_SYSTEM_ORG2_IS_SCRATCH:+1} && "${SF_SR_VAR_SYSTEM_ORG2_IS_SANDBOX,,}" =~ ^true$ && ${SF_SR_VAR_SYSTEM_ORG2_TRIAL_EXPIRATION_DATE:+1} ]]; then
		export SF_SR_VAR_SYSTEM_ORG2_IS_SCRATCH=true
		export SF_SR_VAR_SYSTEM_ORG2_IS_SANDBOX=false
	else
		export SF_SR_VAR_SYSTEM_ORG2_IS_SCRATCH=false
	fi
	
	
	# parse sandbox name from url
	if [[ "${SF_SR_VAR_SYSTEM_ORG2_IS_SANDBOX,,}" =~ ^true$ && ! ${SF_SR_VAR_SYSTEM_ORG2_SANDBOX_NAME:+1} ]]; then
		
		SF_SR_VAR_SYSTEM_ORG2_SANDBOX_NAME="${SF_SR_VAR_SYSTEM_ORG2_INSTANCE_URL##*--}"
		export SF_SR_VAR_SYSTEM_ORG2_SANDBOX_NAME="${SF_SR_VAR_SYSTEM_ORG2_SANDBOX_NAME%%.*}"
		
	fi
	
	
	unset sfOrgDetails
	unset sfAdvancedOrgDetails
	
fi


globalScriptProperties="${PARAM_SCRIPT_SANDBOX_DIR}/.script.properties";

if [[ -f "$globalScriptProperties" ]]; then
    
    # define global script properties (if any) as variables
    echo "Defining global script properties variables..."
    defineVarsFromProps "$globalScriptProperties"
    
fi

if [[ ${PARAM_SCRIPT_PARAMS_FILE:+1} && ! "${PARAM_SCRIPT_PARAMS_FILE,,}" =~ ^none$ && -f "$PARAM_SCRIPT_PARAMS_FILE" ]]; then
    
    # define script params properties (if any) as variables
    echo "Defining script params properties variables..."
    defineVarsFromProps "$PARAM_SCRIPT_PARAMS_FILE"
    
fi



globalStepProperties="${PARAM_SCRIPT_SANDBOX_DIR}/.step.properties";

if [[ -f "$globalStepProperties" ]]; then
    
    # do additional data transformation at global script level (if requested), e.g. copy other steps etc.
    processDataCommands "${globalStepProperties}" "${PARAM_SCRIPT_SANDBOX_DIR}"
    
fi


echo "Current script structure after transformation applied (if any):"
ls -la $PARAM_SCRIPT_SANDBOX_DIR


for file in ${PARAM_SCRIPT_SANDBOX_DIR}/${PARAM_STEP_TO_RUN}; do
    
    echo "Current step to be processed: $file"
    
    if [[ ! -d "${file}" ]]; then
        echo "Skipped current step processing: ${file} is not a directory."
        continue;
    fi
    
    # parse step type and check if it is not disabled
    if [[ "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-([^-]+)(-.*)?$ ]]; then 
        STEP_TYPE="${BASH_REMATCH[1]}";
        echo "Current step type: $STEP_TYPE";
        if [[ ${PARAM_DISABLED_STEP_TYPES:+1} && ",${PARAM_DISABLED_STEP_TYPES^^}," =~ .*\,${STEP_TYPE^^}\,.* ]]; then
            echo "Skipped current step since '${STEP_TYPE}' type is disabled."
            continue;
        fi
    fi
    
    
    echo "Current step structure:"
    ls -la $file
    
    # read and parse step properties from file (if provided)
    
    stepProperties="${file}/.step.properties";
    stepReturnProperties="${file}/.return.properties"
    stepInitScriptBash="${file}/.init.sh";
    stepInitScriptGroovy="${file}/.init.groovy";
    
    unset stepSkip
    unset stepExit
    unset stepFailureIgnore
    sfBulkApiVersion="2.0"
    
    sfApexBeforeEachScriptName="beforeEach.cls"
    sfApexAfterEachScriptName="afterEach.cls"
    
    sfTargetOrg=""
	
	stepRetryAttempts=$STEP_MAX_RETRY_ATTEMPTS
	stepRetryDelay=$STEP_RETRY_DELAY
    
    
    if [[ -f "${stepProperties}" ]]; then
        
        echo "Step properties config detected."
        
        stepExit=$(getProperty $stepProperties "exit")
        stepSkip=$(getProperty $stepProperties "skip")
        stepFailureIgnore=$(getProperty $stepProperties "failure.ignore")
        
        sfBulkApiVersion=$(getProperty $stepProperties "sf.bulkApi.version" "$sfBulkApiVersion")
        
        sfApexBeforeEachScriptName=$(getProperty $stepProperties "sf.apex.beforeEach" "$sfApexBeforeEachScriptName")
        sfApexAfterEachScriptName=$(getProperty $stepProperties "sf.apex.afterEach" "$sfApexAfterEachScriptName")
        
        sfTargetOrg=$(getProperty $stepProperties "sf.targetOrg" "$sfTargetOrg")
		
		stepRetryAttempts=$(getProperty $stepProperties "retry.attempts" "$stepRetryAttempts")
		stepRetryDelay=$(getProperty $stepProperties "retry.delay" "$stepRetryDelay")
		
        
        # handle 'exit'
        if [[ ${stepExit:+1} ]]; then
            stepExit="$(eval $stepExit)"
            if [[ "${stepExit,,}" =~ ^true$ ]]; then 
                echo "Stopped further script execution as requested."
                exit 0;
            fi
        fi
      
        # handle 'skip'
        if [[ ${stepSkip:+1} ]]; then
            stepSkip="$(eval $stepSkip)"
            if [[ "${stepSkip,,}" =~ ^true$ ]]; then 
                echo "Skipped current step as requested."
                continue;
            fi
        fi
        
        # suppress step failures if requested
        if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
            set +e # disable exit on error
            echo "Disabled failures for current step."
        fi
        
        # do additional data transformation (if requested), e.g. copy other artifacts etc.
        processDataCommands "${stepProperties}" "${file}"
        
    fi
	
	
	# step init script (bash)
	if [[ -f "${stepInitScriptBash}" ]]; then
		
		echo "Running step init script (bash)..."
		
		bashStepInitMaxRetryAttempts=$stepRetryAttempts;
		bashStepInitRetryDelay=$stepRetryDelay;
		bashStepInitResultCode=0;
		bashStepInitRetryCounter=0;
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && bashStepInit_backup_errexit='set -e' || bashStepInit_backup_errexit='set +e'; set +e
		
		while true; do 
			
			bash $stepInitScriptBash \
				-a "$PARAM_ORG_ALIAS" \
				-x "$PARAM_ORG2_ALIAS" \
				-w "$file"; bashStepInitResultCode=$?;
				
			# success
			if [[ $bashStepInitResultCode -eq 0 ]]; then
				break;
				
			# failure
			else
				
				echo "ERROR: Bash step init script!"
				
				# retry if not run out of attempts
				if [[ $bashStepInitRetryCounter -lt $bashStepInitMaxRetryAttempts ]]; then
					
					bashStepInitRetryCounter=$(( $bashStepInitRetryCounter + 1 ));
					echo "Retrying bash step init script after failure in ${bashStepInitRetryDelay} seconds (attempt ${bashStepInitRetryCounter}/${bashStepInitMaxRetryAttempts})..."
					sleep $bashStepInitRetryDelay;
					
				# run out of retry attempts: exit with error code
				else
					
					echo "ERROR: Run out of retry attempts (max=${bashStepInitMaxRetryAttempts})"
					exit $bashStepInitResultCode;
					
				fi
				
			fi
			
		done
		
		# restore 'exit on error' flag state
		eval "$bashStepInit_backup_errexit"
		
	fi
	
	
	# step init script (groovy)
	if [[ -f "${stepInitScriptGroovy}" ]]; then
		
		echo "Running step init script (groovy)..."
		
		groovyStepInitMaxRetryAttempts=$stepRetryAttempts;
		groovyStepInitRetryDelay=$stepRetryDelay;
		groovyStepInitResultCode=0;
		groovyStepInitRetryCounter=0;
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && groovyStepInit_backup_errexit='set -e' || groovyStepInit_backup_errexit='set +e'; set +e
		
		while true; do 
			
			java -cp "$groovyClassPath" groovy.lang.GroovyShell $stepInitScriptGroovy \
				--orgAlias="$PARAM_ORG_ALIAS" \
				--orgAlias2="$PARAM_ORG2_ALIAS" \
				--workingDir="$file"; groovyStepInitResultCode=$?;
				
			# success
			if [[ $groovyStepInitResultCode -eq 0 ]]; then
				break;
				
			# failure
			else
				
				echo "ERROR: Groovy step init script!"
				
				# retry if not run out of attempts
				if [[ $groovyStepInitRetryCounter -lt $groovyStepInitMaxRetryAttempts ]]; then
					
					groovyStepInitRetryCounter=$(( $groovyStepInitRetryCounter + 1 ));
					echo "Retrying groovy step init script after failure in ${groovyStepInitRetryDelay} seconds (attempt ${groovyStepInitRetryCounter}/${groovyStepInitMaxRetryAttempts})..."
					sleep $groovyStepInitRetryDelay;
					
				# run out of retry attempts: exit with error code
				else
					
					echo "ERROR: Run out of retry attempts (max=${groovyStepInitMaxRetryAttempts})"
					exit $groovyStepInitResultCode;
					
				fi
				
			fi
			
		done
		
		# restore 'exit on error' flag state
		eval "$groovyStepInit_backup_errexit"
		
	fi
	
	
    # handle collection of nested steps
	if [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-(collection|cookbook|script|recipes|steps)(-[^/]*)?$ ]]; then
		
		echo "Step has been identified as collection of nested steps: $file"
		
		bash $STEPS_RUNNER_UTIL "$@" -d "$file" -o "$file" -w "$PARAM_WORKING_DIR"
		
		echo "Finished processing collection of nested steps."
		continue;
		
	fi
	
	
    # replace dynamic variables (if any) inside artifacts files
    resolveDynamicEnvVarsInFiles "${file}"
    
    
    echo "Current step structure after transformation applied (if any):"
    ls -la $file
    which tree && tree -a $file || true
    
    # check if some non-hidden files exist in step directory (ignoring hidden subdirectories of any level), and skip step processing
    countOfNonHiddenFiles=$(find $file -type f -not -path '*/\.*' | wc -l);
    
    if [[ $countOfNonHiddenFiles -eq 0 ]]; then
        echo "No files to be processed found after transformation in $file folder: skipped current step processing.";
        continue;
    fi
    
    
    # grab org auth info: access token and instance url
    if [[ ${PARAM_ORG_ALIAS:+1} ]]; then
		
		sfOrgDetails=$(getOrgDetails "$PARAM_ORG_ALIAS");
		
		sfAccessToken=$(echo "$sfOrgDetails" | jq -r '.accessToken // empty');
		sfInstanceUrl=$(echo "$sfOrgDetails" | jq -r '.instanceUrl // empty');
		sfDomain=$(echo "$sfInstanceUrl" | cut -d'/' -f3);
		
		# failure
		if [[ ! ${sfAccessToken:+1} || ! ${sfInstanceUrl:+1} ]]; then
			fail "ERROR: Get org auth info for '$PARAM_ORG_ALIAS'!"
		fi
		
        # set target org as the main org
        sfTargetOrgAlias="$PARAM_ORG_ALIAS"
        sfTargetOrgAccessToken="$sfAccessToken"
        sfTargetOrgInstanceUrl="$sfInstanceUrl"
        sfTargetOrgDomain="$sfDomain"
        
    fi
    
    
    # grab optional org2 auth info: access token and instance url
    if [[ ${PARAM_ORG2_ALIAS:+1} ]]; then

		sfOrgDetails2=$(getOrgDetails "$PARAM_ORG2_ALIAS");
		
		sfAccessToken2=$(echo "$sfOrgDetails2" | jq -r '.accessToken // empty');
		sfInstanceUrl2=$(echo "$sfOrgDetails2" | jq -r '.instanceUrl // empty');
		sfDomain2=$(echo "$sfInstanceUrl2" | cut -d'/' -f3);
		
		# failure
		if [[ ! ${sfAccessToken2:+1} || ! ${sfInstanceUrl2:+1} ]]; then
			fail "ERROR: Get org auth info for '$PARAM_ORG2_ALIAS'!"
		fi
		
		# check if org2 has been requested as target org for one-org steps (e.g. metadata deployment, apex execution etc.)
        if [[ "${sfTargetOrg,,}" =~ ^secondary$ ]] ; then
            
            sfTargetOrgAlias="$PARAM_ORG2_ALIAS"
            sfTargetOrgAccessToken="$sfAccessToken2"
            sfTargetOrgInstanceUrl="$sfInstanceUrl2"
			sfTargetOrgDomain="$sfDomain2"
            
        fi
		
    fi
    
    
    # handle metadata deployment step (classic vs source)
    if [[ ${sfTargetOrgAlias:+1} && -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-meta(data)?(-.*)?$ ]]; then
        
        echo "Step has been identified as metadata deployment."
        
		metaStepMaxRetryAttempts=$stepRetryAttempts;
		metaStepRetryDelay=$stepRetryDelay;
		metaStepResultCode=0;
		metaStepRetryCounter=0;
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && metaStep_backup_errexit='set -e' || metaStep_backup_errexit='set +e'; set +e
		
		
		while true; do 	
			
			if [[ -f "${file}/package.xml" ]]; then
				
				echo "Deploying metadata in classic/old format (package.xml has been detected inside folder)..."
				
				# DON'T use '--purgeondelete' option here - it doesn't work in production
				# Error (1): INVALID_OPERATION: purgeOnDelete option can only be used on a non-active org
				sf force mdapi deploy --deploydir="$file" --target-org="$sfTargetOrgAlias" --ignorewarnings --api-version="$SF_API_VERSION" -w 1000 --verbose; metaStepResultCode=$?;
				#sf project deploy start --metadata-dir="$file" -o "$sfTargetOrgAlias" --ignore-conflicts --ignore-warnings --api-version="$SF_API_VERSION" -w 1000 --verbose; metaStepResultCode=$?;
				
			else
				
				echo "Deploying metadata in source format..."
				
				sf force source deploy --sourcepath="$file" --target-org="$sfTargetOrgAlias" --ignorewarnings --api-version="$SF_API_VERSION" -w 1000 --verbose; metaStepResultCode=$?;
				#sf project deploy start -d "$file" -o "$sfTargetOrgAlias" --ignore-conflicts --ignore-warnings --api-version="$SF_API_VERSION" -w 1000 --verbose; metaStepResultCode=$?;
				
			fi
			
			
			# success
			if [[ $metaStepResultCode -eq 0 ]]; then
				break;
				
			# failure
			else
				
				echo "ERROR: Metadata deployment failure!"
				
				# ignore failure
				if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
					echo "Failure has been ignored."
					break;
				fi
				
				# retry if not run out of attempts
				if [[ $metaStepRetryCounter -lt $metaStepMaxRetryAttempts ]]; then
					
					metaStepRetryCounter=$(( $metaStepRetryCounter + 1 ));
					echo "Retrying metadata deployment after failure in ${metaStepRetryDelay} seconds (attempt ${metaStepRetryCounter}/${metaStepMaxRetryAttempts})..."
					sleep $metaStepRetryDelay;
					
				# run out of retry attempts: exit with error code
				else
					
					echo "ERROR: Run out of retry attempts (max=${metaStepMaxRetryAttempts})"
					exit $metaStepResultCode;
					
				fi
				
			fi
			
		done
		
		
		# restore 'exit on error' flag state
		eval "$metaStep_backup_errexit"
        
        
    # handle apex execution step: run all non-hidden top level files inside directory
    elif [[ ${sfTargetOrgAlias:+1} && -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-apex(-.*)?$ ]]; then
        
        echo "Step has been identified as apex execution."
        echo "Iterating over apex scripts available..."
        
        beforeEachApexFile="/dev/null"
        afterEachApexFile="/dev/null"
        
        # catch "before each" script (if any)
        if [[ -f "$file/$sfApexBeforeEachScriptName" ]]; then
            beforeEachApexFile="$file/$sfApexBeforeEachScriptName"
        fi
        
        # catch "after each" script (if any)
        if [[ -f "$file/$sfApexAfterEachScriptName" ]]; then
            afterEachApexFile="$file/$sfApexAfterEachScriptName"
        fi
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && apexStep_backup_errexit='set -e' || apexStep_backup_errexit='set +e'; set +e
        
		
        for apexFile in ${file}/*; do
            
            if [[ -f "$apexFile" && "${apexFile}" =~ ^.*/[^/.][^/]*$ && "${apexFile}" != "${beforeEachApexFile}" && "${apexFile}" != "${afterEachApexFile}" ]]; then
                
				apexStepMaxRetryAttempts=$stepRetryAttempts;
				apexStepRetryDelay=$stepRetryDelay;
				apexStepResultCode=0;
				apexStepRetryCounter=0;
				
				apexFileName="$(basename -- "$apexFile")";
				
				while true; do 
					
					APEX_EXEC_RESPONSE=$(cat $beforeEachApexFile <(echo) $apexFile <(echo) $afterEachApexFile | sf apex run --target-org "$sfTargetOrgAlias" --api-version="$SF_API_VERSION" --json | sed '/[Ss]tart typing [Aa]pex code/d');
					apexStepResultCode=$(echo "$APEX_EXEC_RESPONSE" | jq .status);
					
					# success
					if [[ $apexStepResultCode -eq 0 ]]; then
						
						# grab return values from execution logs (if any)
						echo "$APEX_EXEC_RESPONSE" | 
							jq -r ".result.logs // empty" | 
							grep '|USER_DEBUG|' | 
							grep -i 'ApexScriptReturnValue:' | 
							grep -oi "\{.*\}" | 
							jq -r '. | to_entries | .[] | .key + "=" + (.value | @sh)' >> ${stepReturnProperties}
						
						echo "Apex script '$apexFileName' has been successfully executed."
						
						break;
						
					# apex exec fail
					else
						
						APEX_EXEC_EXCEPTION_MESSAGE=$(echo "$APEX_EXEC_RESPONSE" | jq -r ".data.exceptionMessage // empty");
						
						# not an actual failure but workaround to return value in exception message
						if [[ "${APEX_EXEC_EXCEPTION_MESSAGE,,}" =~ ^apexscriptreturnvalueexception:.*$ ]]; then
							
							echo "$APEX_EXEC_EXCEPTION_MESSAGE" | grep -oi "\{.*\}" | jq -r '. | to_entries | .[] | .key + "=" + (.value | @sh)' >> ${stepReturnProperties}
							
							echo "Apex script '$apexFileName' has been successfully executed."
							
							break;
							
						# actual exception
						else
							
							echo "ERROR: Apex script '$apexFileName' execution failure!"
							echo "$APEX_EXEC_RESPONSE" | jq .
							
							# ignore failure
							if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
								echo "Failure has been ignored."
								break;
							fi
							
							# retry if not run out of attempts
							if [[ $apexStepRetryCounter -lt $apexStepMaxRetryAttempts ]]; then
								
								apexStepRetryCounter=$(( $apexStepRetryCounter + 1 ));
								echo "Retrying apex script execution ($apexFileName) after failure in ${apexStepRetryDelay} seconds (attempt ${apexStepRetryCounter}/${apexStepMaxRetryAttempts})..."
								sleep $apexStepRetryDelay;
								
							# run out of retry attempts: exit with error code
							else
								
								echo "ERROR: Run out of retry attempts (max=${apexStepMaxRetryAttempts})"
								exit $apexStepResultCode;
								
							fi
							
						fi
						
					fi
            
				done
                
            fi
            
        done
		
		# restore 'exit on error' flag state
		eval "$apexStep_backup_errexit"
        
        
    # handle bash execution step: run all non-hidden top level files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-(shell|bash)(-.*)?$ ]]; then
        
        echo "Step has been identified as shell execution."
        echo "Iterating over shell scripts available..."
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && bashStep_backup_errexit='set -e' || bashStep_backup_errexit='set +e'; set +e
        
        for bashFile in ${file}/*.sh; do
            
            if [[ -f "$bashFile" && "${bashFile}" =~ ^.*/[^/.][^/]*$ ]]; then 
				
				bashStepMaxRetryAttempts=$stepRetryAttempts;
				bashStepRetryDelay=$stepRetryDelay;
				bashStepResultCode=0;
				bashStepRetryCounter=0;
				
				while true; do 
					
					bash $bashFile \
						-a "$PARAM_ORG_ALIAS" -r "$sfInstanceUrl" -t "$sfAccessToken" -v "$SF_API_VERSION" \
						-x "$PARAM_ORG2_ALIAS" -l "$sfInstanceUrl2" -j "$sfAccessToken2" -z "$SF_API_VERSION" \
						-w "$PARAM_WORKING_DIR"; bashStepResultCode=$?;
					
					# success
					if [[ $bashStepResultCode -eq 0 ]]; then
						break;
						
					# failure
					else
						
						echo "ERROR: Bash script execution failure - ${bashFile}!"
						
						# ignore failure
						if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
							echo "Failure has been ignored."
							break;
						fi
						
						# retry if not run out of attempts
						if [[ $bashStepRetryCounter -lt $bashStepMaxRetryAttempts ]]; then
							
							bashStepRetryCounter=$(( $bashStepRetryCounter + 1 ));
							echo "Retrying bash script execution ($bashFile) after failure in ${bashStepRetryDelay} seconds (attempt ${bashStepRetryCounter}/${bashStepMaxRetryAttempts})..."
							sleep $bashStepRetryDelay;
							
						# run out of retry attempts: exit with error code
						else
							
							echo "ERROR: Run out of retry attempts (max=${bashStepMaxRetryAttempts})"
							exit $bashStepResultCode;
							
						fi
						
					fi
					
				done
				
            fi
            
        done
		
		# restore 'exit on error' flag state
		eval "$bashStep_backup_errexit"
        
        
    # handle node execution step: run all non-hidden top level js files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-(node|puppeteer)(-.*)?$ ]]; then
        
        echo "Step has been identified as nodejs execution."
        
        pushd $file
        
        if [[ -f "package.json" ]]; then
            npm install
        fi
        
        echo "Iterating over js scripts available..."
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && nodeStep_backup_errexit='set -e' || nodeStep_backup_errexit='set +e'; set +e
        
        for jsFile in *.js; do
			
            if [[ -f "$jsFile" && "${jsFile}" =~ ^[^.].*$ ]]; then 
				
				nodeStepMaxRetryAttempts=$stepRetryAttempts;
				nodeStepRetryDelay=$stepRetryDelay;
				nodeStepResultCode=0;
				nodeStepRetryCounter=0;
				
				while true; do 
				
					node $jsFile \
						--orgAlias="$PARAM_ORG_ALIAS" --accessToken="$sfAccessToken" --instanceUrl="$sfInstanceUrl" --apiVersion="$SF_API_VERSION" \
						--orgAlias2="$PARAM_ORG2_ALIAS" --accessToken2="$sfAccessToken2" --instanceUrl2="$sfInstanceUrl2" --apiVersion2="$SF_API_VERSION" \
						--workingDir="$PARAM_WORKING_DIR"; nodeStepResultCode=$?;
						
					# success
					if [[ $nodeStepResultCode -eq 0 ]]; then
						break;
						
					# failure
					else
						
						echo "ERROR: Node script execution failure - ${jsFile}!"
						
						# ignore failure
						if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
							echo "Failure has been ignored."
							break;
						fi
						
						# retry if not run out of attempts
						if [[ $nodeStepRetryCounter -lt $nodeStepMaxRetryAttempts ]]; then
							
							nodeStepRetryCounter=$(( $nodeStepRetryCounter + 1 ));
							echo "Retrying node script execution ($jsFile) after failure in ${nodeStepRetryDelay} seconds (attempt ${nodeStepRetryCounter}/${nodeStepMaxRetryAttempts})..."
							sleep $nodeStepRetryDelay;
							
						# run out of retry attempts: exit with error code
						else
							
							echo "ERROR: Run out of retry attempts (max=${nodeStepMaxRetryAttempts})"
							exit $nodeStepResultCode;
							
						fi
						
					fi
					
				done
				
            fi
			
        done
		
		# restore 'exit on error' flag state
		eval "$nodeStep_backup_errexit"
        
        popd
        
        
    # handle jsforce execution step: run all non-hidden top level js files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-jsforce(-.*)?$ ]]; then
        
        echo "Step has been identified as jsforce execution."
        
        if ! command -v sf-run-jsforce &> /dev/null; then
            npm install -g sf-jsforce-runner@${JSFORCE_RUNNER_VERSION}
        fi
        
        pushd $file
        
        echo "Iterating over js scripts available..."
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && jsforceStep_backup_errexit='set -e' || jsforceStep_backup_errexit='set +e'; set +e
        
        for jsFile in *.js; do
			
            if [[ -f "$jsFile" && "${jsFile}" =~ ^[^.].*$ ]]; then 
				
				jsforceStepMaxRetryAttempts=$stepRetryAttempts;
				jsforceStepRetryDelay=$stepRetryDelay;
				jsforceStepResultCode=0;
				jsforceStepRetryCounter=0;
				
				while true; do 
					
					sf-run-jsforce $jsFile \
						--orgAlias="$PARAM_ORG_ALIAS" --accessToken="$sfAccessToken" --instanceUrl="$sfInstanceUrl" --apiVersion="$SF_API_VERSION" \
						--orgAlias2="$PARAM_ORG2_ALIAS" --accessToken2="$sfAccessToken2" --instanceUrl2="$sfInstanceUrl2" --apiVersion2="$SF_API_VERSION" \
						--workingDir="$PARAM_WORKING_DIR";  jsforceStepResultCode=$?;
					
					# success
					if [[ $jsforceStepResultCode -eq 0 ]]; then
						break;
						
					# failure
					else
						
						echo "ERROR: JSForce script execution failure - ${jsFile}!"
						
						# ignore failure
						if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
							echo "Failure has been ignored."
							break;
						fi
						
						# retry if not run out of attempts
						if [[ $jsforceStepRetryCounter -lt $jsforceStepMaxRetryAttempts ]]; then
							
							jsforceStepRetryCounter=$(( $jsforceStepRetryCounter + 1 ));
							echo "Retrying jsforce script execution ($jsFile) after failure in ${jsforceStepRetryDelay} seconds (attempt ${jsforceStepRetryCounter}/${jsforceStepMaxRetryAttempts})..."
							sleep $jsforceStepRetryDelay;
							
						# run out of retry attempts: exit with error code
						else
							
							echo "ERROR: Run out of retry attempts (max=${jsforceStepMaxRetryAttempts})"
							exit $jsforceStepResultCode;
							
						fi
						
					fi
					
				done
				
            fi
			
        done
		
		# restore 'exit on error' flag state
		eval "$jsforceStep_backup_errexit"
        
        popd
        
        
    # handle python execution step: run all non-hidden top level py files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-python(-.*)?$ ]]; then
        
        echo "Step has been identified as python execution."
        
        pushd $file
        
        if [[ -f "requirements.txt" ]]; then
            pip install -r requirements.txt
        fi
        
        echo "Iterating over py scripts available..."
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && pythonStep_backup_errexit='set -e' || pythonStep_backup_errexit='set +e'; set +e
        
        for pyFile in *.py; do
			
            if [[ -f "$pyFile" && "${pyFile}" =~ ^[^.].*$ ]]; then 
				
				pythonStepMaxRetryAttempts=$stepRetryAttempts;
				pythonStepRetryDelay=$stepRetryDelay;
				pythonStepResultCode=0;
				pythonStepRetryCounter=0;
				
				while true; do 
					
					python $pyFile \
						--orgAlias="$PARAM_ORG_ALIAS" --accessToken="$sfAccessToken" --instanceUrl="$sfInstanceUrl" --apiVersion="$SF_API_VERSION" \
						--orgAlias2="$PARAM_ORG2_ALIAS" --accessToken2="$sfAccessToken2" --instanceUrl2="$sfInstanceUrl2" --apiVersion2="$SF_API_VERSION" \
						--workingDir="$PARAM_WORKING_DIR"; pythonStepResultCode=$?;
						
					# success
					if [[ $pythonStepResultCode -eq 0 ]]; then
						break;
						
					# failure
					else
						
						echo "ERROR: Python script execution failure - ${pyFile}!"
						
						# ignore failure
						if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
							echo "Failure has been ignored."
							break;
						fi
						
						# retry if not run out of attempts
						if [[ $pythonStepRetryCounter -lt $pythonStepMaxRetryAttempts ]]; then
							
							pythonStepRetryCounter=$(( $pythonStepRetryCounter + 1 ));
							echo "Retrying python script execution ($pyFile) after failure in ${pythonStepRetryDelay} seconds (attempt ${pythonStepRetryCounter}/${pythonStepMaxRetryAttempts})..."
							sleep $pythonStepRetryDelay;
							
						# run out of retry attempts: exit with error code
						else
							
							echo "ERROR: Run out of retry attempts (max=${pythonStepMaxRetryAttempts})"
							exit $pythonStepResultCode;
							
						fi
						
					fi
					
				done
				
            fi
			
        done
		
		# restore 'exit on error' flag state
		eval "$pythonStep_backup_errexit"
        
        popd
		
        
    # handle robot execution step: run all non-hidden top level robot files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-robot(-.*)?$ ]]; then
        
        echo "Step has been identified as robot execution."
		
		#if ! command -v Xvfb &> /dev/null; then
		#	apt install xvfb
		#fi
		
		#pip install --user virtualenv
		#python -m venv .venv
		#source .venv/bin/activate
        
        if ! command -v robot &> /dev/null; then
			
			pip install robotframework
			
			# use requirements.txt in step folder to install additional libraries
			#pip install robotframework-seleniumlibrary
			#pip install QWeb
			
			#Xvfb :99 &
			
        fi
		
        pushd $file
        
        if [[ -f "requirements.txt" ]]; then
            pip install -r requirements.txt
        fi
        
        echo "Iterating over robot scripts available..."
        
        for robotFile in *.robot; do
            if [[ -f "$robotFile" && "${robotFile}" =~ ^[^.].*$ ]]; then 
                #export DISPLAY=:99
				#--variable "browser_options:--headless"
				robot \
					--variable "ORG_ALIAS:$PARAM_ORG_ALIAS" --variable "ACCESS_TOKEN:$sfAccessToken" --variable "INSTANCE_URL:$sfInstanceUrl" --variable "API_VERSION:$SF_API_VERSION" \
					--variable "ORG_ALIAS2:$PARAM_ORG_ALIAS" --variable "ACCESS_TOKEN2:$sfAccessToken" --variable "INSTANCE_URL2:$sfInstanceUrl" --variable "API_VERSION2:$SF_API_VERSION" \
					--variable "WORKING_DIR:$PARAM_WORKING_DIR" \
					$robotFile
            fi
        done
		
		#deactivate
        
        popd
		
		
    # handle playwright execution step: run all tests
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-playwright(-.*)?$ ]]; then
        
        echo "Step has been identified as playwright execution."
        
        pushd $file
        
        if [[ -f "package.json" ]]; then
            npm install
        fi
		
		#npx playwright install --force chrome --with-deps
		npx playwright install
		
		# evaluate debug mode
		if [[ $DEBUG_MODE -ge 1 ]]; then
			PLAYWRIGHT_DEBUG_MODE="pw:api"
		else
			PLAYWRIGHT_DEBUG_MODE=""
		fi
	    
		# run all tests
		DEBUG=$PLAYWRIGHT_DEBUG_MODE CI=true PLAYWRIGHT_ORG_ALIAS="$PARAM_ORG_ALIAS" PLAYWRIGHT_ACCESS_TOKEN="$sfAccessToken" PLAYWRIGHT_INSTANCE_URL="$sfInstanceUrl" PLAYWRIGHT_ORG2_ALIAS="$PARAM_ORG2_ALIAS" PLAYWRIGHT_ACCESS_TOKEN2="$sfAccessToken2" PLAYWRIGHT_INSTANCE_URL2="$sfInstanceUrl2" PLAYWRIGHT_WORKING_DIR="$PARAM_WORKING_DIR" npx playwright test
        
        popd
        
        
    # handle data execution step: process all non-hidden top level csv files inside directory
    elif [[ ${sfTargetOrgAlias:+1} && -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-data(-.*)?$ ]]; then
        
        echo "Step has been identified as data ingestion."
        
        if ! command -v sf-run-jsforce &> /dev/null; then
            npm install -g sf-jsforce-runner@${JSFORCE_RUNNER_VERSION}
        fi
        
        echo "Iterating over csv files available..."
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && dataStep_backup_errexit='set -e' || dataStep_backup_errexit='set +e'; set +e
        
        for csvFile in ${file}/*.csv; do
            
            if [[ -f "$csvFile" && "${csvFile}" =~ ^.*/[^/.][^/]*$ ]]; then 
                
                # ignore result files, e.g. left from previous runs
                if [[ "${csvFile}" =~ ^.*[.]result[^a-zA-Z0-9].*$ ]]; then 
                    continue;
                fi
				
				dataStepMaxRetryAttempts=$stepRetryAttempts;
				dataStepRetryDelay=$stepRetryDelay;
				dataStepResultCode=0;
				dataStepRetryCounter=0;
				
				while true; do 
					
					sf-run-jsforce scripts/jsforce/loadData-${sfBulkApiVersion}.js \
						--accessToken="$sfTargetOrgAccessToken" --instanceUrl="$sfTargetOrgInstanceUrl" --apiVersion="$SF_API_VERSION" \
						--dataFile="$csvFile"; dataStepResultCode=$?;
						
					
					# success
					if [[ $dataStepResultCode -eq 0 ]]; then
						break;
						
					# failure
					else
						
						echo "ERROR: Data script execution failure - ${csvFile}!"
						
						# ignore failure
						if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
							echo "Failure has been ignored."
							break;
						fi
						
						# retry if not run out of attempts
						if [[ $dataStepRetryCounter -lt $dataStepMaxRetryAttempts ]]; then
							
							dataStepRetryCounter=$(( $dataStepRetryCounter + 1 ));
							echo "Retrying data script execution ($csvFile) after failure in ${dataStepRetryDelay} seconds (attempt ${dataStepRetryCounter}/${dataStepMaxRetryAttempts})..."
							sleep $dataStepRetryDelay;
							
						# run out of retry attempts: exit with error code
						else
							
							echo "ERROR: Run out of retry attempts (max=${dataStepMaxRetryAttempts})"
							exit $dataStepResultCode;
							
						fi
						
					fi
					
				done
				
            fi
            
        done
		
		# restore 'exit on error' flag state
		eval "$dataStep_backup_errexit"
        
		
	# handle data SFDMU execution step: expected content of the directory to be in format acceptable by SFDMU pugin, i.e. with export.json file and bunch of csvs inside
    elif [[ ${sfTargetOrgAlias:+1} && -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-datasfdmu(-.*)?$ ]]; then
		
		echo "Step has been identified as SFDMU data ingestion."
		
		pushd $file
		
		echo "Installing sfdmu plugin if no originally installed version is available ..."
		(sf plugins | grep -i "sfdmu") || (echo "y" | sf plugins install sfdmu@$SFDMU_PLUGIN_VERSION)
		
		dataStepMaxRetryAttempts=1;
		dataStepRetryDelay=30;
		dataStepResultCode=0;
		dataStepRetryCounter=0;
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && dataStep_backup_errexit='set -e' || dataStep_backup_errexit='set +e'; set +e
		
		
		while true; do 	
			
			sf sfdmu:run --sourceusername="csvfile" --targetusername="$sfTargetOrgAlias" --apiversion="$SF_API_VERSION" --canmodify="$sfTargetOrgDomain" --noprompt --logfullquery --verbose; dataStepResultCode=$?;
			
			
			# print warning/error files (if any)
			if [[ -s "CSVIssuesReport.csv" ]]; then
				echo "Detected CSVIssuesReport.csv file:"
				cat CSVIssuesReport.csv
			fi
			
			if [[ -s "MissingParentRecordsReport.csv" ]]; then
				echo "Detected MissingParentRecordsReport.csv file:"
				cat MissingParentRecordsReport.csv
			fi
			
			
			# success
			if [[ $dataStepResultCode -eq 0 ]]; then
				break;
				
			# failure
			else
				
				echo "ERROR: Data SFDMU load failure!"
				
				# ignore failure
				if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
					echo "Failure has been ignored."
					break;
				fi
				
				
				# print result records
				#if [[ -d "target" && $DEBUG_MODE -ge 1 ]]; then
				if [[ -d "target" ]]; then
					find ./target -type f -name "*.csv" | xargs tail -n +1
				fi
		
				# print logs in debug mode
				if [[ -d "logs" && $DEBUG_MODE -ge 1 ]]; then
					cat logs/*.log
				fi
				
				
				# retry if not run out of attempts
				if [[ $dataStepRetryCounter -lt $dataStepMaxRetryAttempts ]]; then
					
					dataStepRetryCounter=$(( $dataStepRetryCounter + 1 ));
					echo "Retrying data SFDMU load after failure in ${dataStepRetryDelay} seconds (attempt ${dataStepRetryCounter}/${dataStepMaxRetryAttempts})..."
					sleep $dataStepRetryDelay;
					
				# run out of retry attempts: exit with error code
				else
					
					echo "ERROR: Run out of retry attempts (max=${dataStepMaxRetryAttempts})"
					exit $dataStepResultCode;
					
				fi
				
			fi
			
		done
		
		
		# print result records
		#if [[ -d "target" && $DEBUG_MODE -ge 1 ]]; then
		if [[ -d "target" ]]; then
			find ./target -type f -name "*.csv" | xargs tail -n +1
		fi
		
		# print logs in debug mode
		if [[ -d "logs" && $DEBUG_MODE -ge 1 ]]; then
			cat logs/*.log
		fi
		
		
		# restore 'exit on error' flag state
		eval "$dataStep_backup_errexit"
		
		popd
		
        
    # handle groovy execution step: run all non-hidden top level groovy files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-groovy(-.*)?$ ]]; then
        
        echo "Step has been identified as groovy execution."
        
        echo "Groovy classpath to be used: $groovyClassPath"
        
        pushd $file
        
        echo "Iterating over groovy scripts available..."
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && groovyStep_backup_errexit='set -e' || groovyStep_backup_errexit='set +e'; set +e
        
        for groovyFile in *.groovy; do
			
            if [[ -f "$groovyFile" && "${groovyFile}" =~ ^[^.].*$ ]]; then 
				
				groovyStepMaxRetryAttempts=$stepRetryAttempts;
				groovyStepRetryDelay=$stepRetryDelay;
				groovyStepResultCode=0;
				groovyStepRetryCounter=0;
				
				while true; do 
					
					java -cp "$groovyClassPath" groovy.lang.GroovyShell $groovyFile \
						--orgAlias="$PARAM_ORG_ALIAS" --accessToken="$sfAccessToken" --instanceUrl="$sfInstanceUrl" --apiVersion="$SF_API_VERSION" \
						--orgAlias2="$PARAM_ORG2_ALIAS" --accessToken2="$sfAccessToken2" --instanceUrl2="$sfInstanceUrl2" --apiVersion2="$SF_API_VERSION" \
						--workingDir="$PARAM_WORKING_DIR"; groovyStepResultCode=$?;
						
					
					# success
					if [[ $groovyStepResultCode -eq 0 ]]; then
						break;
						
					# failure
					else
						
						echo "ERROR: Groovy script execution failure - ${groovyFile}!"
						
						# ignore failure
						if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
							echo "Failure has been ignored."
							break;
						fi
						
						# retry if not run out of attempts
						if [[ $groovyStepRetryCounter -lt $groovyStepMaxRetryAttempts ]]; then
							
							groovyStepRetryCounter=$(( $groovyStepRetryCounter + 1 ));
							echo "Retrying groovy script execution ($groovyFile) after failure in ${groovyStepRetryDelay} seconds (attempt ${groovyStepRetryCounter}/${groovyStepMaxRetryAttempts})..."
							sleep $groovyStepRetryDelay;
							
						# run out of retry attempts: exit with error code
						else
							
							echo "ERROR: Run out of retry attempts (max=${groovyStepMaxRetryAttempts})"
							exit $groovyStepResultCode;
							
						fi
						
					fi
					
				done
				
            fi
			
        done
		
		# restore 'exit on error' flag state
		eval "$groovyStep_backup_errexit"
        
        popd
        
        
    # handle ant execution step: run all non-hidden top level xml files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-ant(-.*)?$ ]]; then
        
        echo "Step has been identified as ant execution."
        
        pushd $file
        
        echo "Iterating over xml scripts available..."
		
		# backup current error switcher value and disable exit on error
		[ -o errexit ] && antStep_backup_errexit='set -e' || antStep_backup_errexit='set +e'; set +e
        
        for antFile in *.xml; do
			
            if [[ -f "$antFile" && "${antFile}" =~ ^[^.].*$ ]]; then 
				
				antStepMaxRetryAttempts=$stepRetryAttempts;
				antStepRetryDelay=$stepRetryDelay;
				antStepResultCode=0;
				antStepRetryCounter=0;
				
				while true; do 
					
					ant -f $antFile \
						-DorgAlias="$PARAM_ORG_ALIAS" -DaccessToken="$sfAccessToken" -DinstanceUrl="$sfInstanceUrl" -DapiVersion="$SF_API_VERSION" \
						-DorgAlias2="$PARAM_ORG2_ALIAS" -DaccessToken2="$sfAccessToken2" -DinstanceUrl2="$sfInstanceUrl2" -DapiVersion2="$SF_API_VERSION" \
						-DworkingDir="$PARAM_WORKING_DIR"; antStepResultCode=$?;
						
					
					# success
					if [[ $antStepResultCode -eq 0 ]]; then
						break;
						
					# failure
					else
						
						echo "ERROR: Ant script execution failure - ${antFile}!"
						
						# ignore failure
						if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
							echo "Failure has been ignored."
							break;
						fi
						
						# retry if not run out of attempts
						if [[ $antStepRetryCounter -lt $antStepMaxRetryAttempts ]]; then
							
							antStepRetryCounter=$(( $antStepRetryCounter + 1 ));
							echo "Retrying ant script execution ($antFile) after failure in ${antStepRetryDelay} seconds (attempt ${antStepRetryCounter}/${antStepMaxRetryAttempts})..."
							sleep $antStepRetryDelay;
							
						# run out of retry attempts: exit with error code
						else
							
							echo "ERROR: Run out of retry attempts (max=${antStepMaxRetryAttempts})"
							exit $antStepResultCode;
							
						fi
						
					fi
					
				done
				
            fi
			
        done
		
		# restore 'exit on error' flag state
		eval "$antStep_backup_errexit"
        
        popd
		
		
    # handle postman execution step: run all non-hidden top level json files inside directory
    elif [[ -d "$file" && "${file,,}" =~ ^.*/${STEP_INDEX_REGEX}-postman(-.*)?$ ]]; then
        
        echo "Step has been identified as postman execution."
        
        if ! command -v sf-run-postman &> /dev/null; then
            npm install -g sf-postman-runner@${POSTMAN_RUNNER_VERSION}
        fi
        
        pushd $file
        
        echo "Iterating over json scripts available..."
        
        for postmanFile in *.json; do
			
            if [[ -f "$postmanFile" && "${postmanFile}" =~ ^[^.].*$ ]]; then 
				
				# check for optional environment file
				if [[ -f "envs/${postmanFile}" ]]; then
					postmanEnvFile="envs/${postmanFile}";
					echo "Found specific postman env file: $postmanEnvFile"
				elif [[ -f "envs/default.json" ]]; then
					postmanEnvFile="envs/default.json";
					echo "Found default postman env file: $postmanEnvFile"
				else
					postmanEnvFile=""
					echo "No postman env file detected!"
				fi
				
                sf-run-postman $postmanFile \
                    --orgAlias="$PARAM_ORG_ALIAS" --accessToken="$sfAccessToken" --instanceUrl="$sfInstanceUrl" --apiVersion="$SF_API_VERSION" \
                    --orgAlias2="$PARAM_ORG2_ALIAS" --accessToken2="$sfAccessToken2" --instanceUrl2="$sfInstanceUrl2" --apiVersion2="$SF_API_VERSION" \
                    --workingDir="$PARAM_WORKING_DIR" --environment="$postmanEnvFile"
				
            fi
			
        done
        
        popd
        
    fi
    
    
    # define variables from return file produced by step processing (if any)
    if [[ -s "$stepReturnProperties" ]]; then
        echo "Defining variables from return file..."
        defineVarsFromProps "$stepReturnProperties"
    fi
    
    
    # reset back step failures suppression
    if [[ "${stepFailureIgnore,,}" =~ ^true$ ]]; then
        set -e # enable exit on error back
    fi
    
done

########################## MAIN (END)

