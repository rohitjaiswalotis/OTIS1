
import groovy.io.FileType;
import groovy.cli.commons.CliBuilder;
import groovy.json.JsonSlurper;

import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;
import com.toolset.validator.ApexClassValidator;
import com.toolset.validator.ObjectValidator;
import com.toolset.validator.FieldValidator;
import com.toolset.validator.ApexTriggerValidator;
import com.toolset.validator.VisualForcePageValidator;
import com.toolset.validator.FlexiPageValidator;
import com.toolset.validator.PermissionSetValidator;
import com.toolset.validator.CustomPermissionValidator;
import com.toolset.validator.LwcValidator;
import com.toolset.validator.AuraValidator;
import com.toolset.validator.CustomLabelValidator;
import com.toolset.validator.EmailTemplateValidator;
import com.toolset.validator.ReportValidator;
import com.toolset.validator.DashboardValidator;


def env = System.getenv();


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


// parse project config

def projectConfigFile = new File(options.workingDir, env['PROJECTCONFIGFILE'] ?: 'sfdx-project.json');

if (!projectConfigFile.exists()) {
	throw new Exception("Cannot find project config file: ${projectConfigFile?.absolutePath}");
}

def projectConfig = new JsonSlurper().parseText(BundleHelper.readFile(projectConfigFile)) as Map;

// early exit - no custom scope provided
/*
if (!projectConfig?.customScope?.name) {
	System.out.println("No custom scope detected in project config file.");
	return;
}
*/

def defaultPackage = projectConfig.packageDirectories?.find { pkg -> pkg.default == true }

// early exit - no default package configured
if (!defaultPackage) {
	System.out.println("No default package set in project config file.");
	return;
}


def packageDir = new File(options.workingDir, defaultPackage.path);

def scopeName = projectConfig?.customScope?.name;
def scopeExclusions = projectConfig.customScope.exclusions;

// define validators chain
List<Validator> validators = [
	new ApexClassValidator(packageDir, scopeName, scopeExclusions?.classes),
	new ObjectValidator(packageDir, scopeName, scopeExclusions?.objects),
	new FieldValidator(packageDir, scopeName, scopeExclusions?.fields),
	new ApexTriggerValidator(packageDir, scopeName, scopeExclusions?.triggers),
	new VisualForcePageValidator(packageDir, scopeName, scopeExclusions?.pages),
	new FlexiPageValidator(packageDir, scopeName, scopeExclusions?.flexipages),
	new PermissionSetValidator(packageDir, scopeName, scopeExclusions?.permissionsets),
	new CustomPermissionValidator(packageDir, scopeName, scopeExclusions?.customPermissions),
	new LwcValidator(packageDir, scopeName, scopeExclusions?.lwc),
	new AuraValidator(packageDir, scopeName, scopeExclusions?.aura),
	//new EmailTemplateValidator(packageDir, scopeName, scopeExclusions?.emails),
	new ReportValidator(packageDir, scopeName, scopeExclusions?.reports),
	new DashboardValidator(packageDir, scopeName, scopeExclusions?.reports),
	new CustomLabelValidator(packageDir, scopeName, scopeExclusions?.labels)
];


Boolean isSuccess = true;

// run actual validation
validators.each { validator -> 
	
	if (validator.skip() == true) {
		System.out.println("Skipped validation by '${validator.getName()}'.");
		return;
	}
	
	def errors = validator.validate();
	
	if (!errors) {
		System.out.println("No validation errors detected by '${validator.getName()}'.");
		return;
	}
	
	System.err.println("Detected the following validation errors by '${validator.getName()}':");
	
	errors.each {
		System.err.println('ERROR: ' + it);
	};
	
	isSuccess = false;
	
}


if (isSuccess == false) {
	System.exit(-1);
}


