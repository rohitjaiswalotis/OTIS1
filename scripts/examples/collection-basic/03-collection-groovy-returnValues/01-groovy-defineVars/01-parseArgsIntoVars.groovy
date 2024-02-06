
import groovy.cli.commons.CliBuilder;
import com.toolset.helper.ObjectHelper;

println "Parsing args inside groovy script...";


// parse command line arguments keys

def cli = new CliBuilder(usage:'script [options]').tap {
	
	_(longOpt:'orgAlias', type: String, 'Org Alias')
	_(longOpt:'accessToken', type: String, 'Access Token')
	_(longOpt:'instanceUrl', type: String, 'Instance Url')
	_(longOpt:'apiVersion', type: String, 'Api Version')
	
	_(longOpt:'orgAlias2', type: String, 'Second Org Alias')
	_(longOpt:'accessToken2', type: String, 'Second Org Access Token')
	_(longOpt:'instanceUrl2', type: String, 'Second Org Instance Url')
	_(longOpt:'apiVersion2', type: String, 'Second Org Api Version')
	
	_(longOpt:'workingDir', type: String, 'Working Directory')
	
}

def options = cli.parse(args);


println "Parsed arguments:"
println "orgAlias=${options.orgAlias}"
println "instanceUrl=${options.instanceUrl}"
println "apiVersion=${options.apiVersion}"
println "workingDir=${options.workingDir}"
println "isAccountCustomObject=${ObjectHelper.isCustomObject('Account')}"
println "isBranchCustomObject=${ObjectHelper.isCustomObject('Branch__c')}"

def returnFile = new File('.return.properties');

returnFile.withWriterAppend { fileWriter ->			
	
	fileWriter.println("SF_SR_VAR_SCRIPT_LANGUAGE=Groovy");
	fileWriter.println("SF_SR_VAR_ORG_ALIAS=${options.orgAlias}");
	fileWriter.println("SF_SR_VAR_SF_INSTANCE_URL=${options.instanceUrl}");
	fileWriter.println("SF_SR_VAR_SF_API_VERSION=${options.apiVersion}");
	fileWriter.println("SF_SR_VAR_WORKING_DIR=${options.workingDir}");
	
}


