package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;



public class ApiVersionValidator implements Validator {
	
	public static final def EXCLUDE_MARKER_REGEX = /(?i)<!--\s*require\s+specific\s+version\s*-->/;
	
	
	private Double minApiVersion;
	private Double maxApiVersion;
	private File artifactsDir;
	
	
	
	public ApiVersionValidator(File artifactsDir, def minApiVersion, def maxApiVersion) {
		
		this.artifactsDir = artifactsDir;
		
		this.minApiVersion = minApiVersion as Double;
		this.maxApiVersion = maxApiVersion as Double;
		
	}
	
	
	public Boolean skip() {
		
		return (
			!this.minApiVersion
			&&
			!this.maxApiVersion
		);
		
	}
	
	
	public List<String> validate() {
		
		List<String> errors = [];
		
		
		// loop through apex classes
		BundleHelper.forEachClass(artifactsDir) { className, classFile, metaName, metaFile, metaRoot, Double metaApiVersion ->
			
			errors.addAll(
				validateDescriptorPresence('Apex class', className, metaFile)
			);
			
			errors.addAll(
				validateApiVersion('Apex class', className, metaFile, metaApiVersion)
			);
			
			errors.addAll(
				validateDependencyFromPackageVersions('Apex class', className, metaFile, metaRoot)
			);
			
		}
		
		
		// loop through apex triggers
		BundleHelper.forEachTrigger(artifactsDir) { triggerName, triggerFile, triggerObject, metaFile, metaRoot, Double metaApiVersion ->
			
			errors.addAll(
				validateDescriptorPresence('Apex trigger', triggerName, metaFile)
			);
			
			errors.addAll(
				validateApiVersion('Apex trigger', triggerName, metaFile, metaApiVersion)
			);
			
			errors.addAll(
				validateDependencyFromPackageVersions('Apex trigger', triggerName, metaFile, metaRoot)
			);
			
		}
		
		
		// loop through vf pages
		BundleHelper.forEachVisualForcePage(artifactsDir) { pageName, pageFile, metaFile, metaRoot, Double metaApiVersion ->
			
			errors.addAll(
				validateDescriptorPresence('VF page', pageName, metaFile)
			);
			
			errors.addAll(
				validateApiVersion('VF page', pageName, metaFile, metaApiVersion)
			);
			
			errors.addAll(
				validateDependencyFromPackageVersions('VF page', pageName, metaFile, metaRoot)
			);
			
		}
		
		
		// loop through aura components
		BundleHelper.forEachAura(artifactsDir) { componentName, componentFiles, metaRoot, metaApiVersion -> 
			
			errors.addAll(
				validateDescriptorPresence('Aura component', componentName, componentFiles.xmlFile)
			);
			
			errors.addAll(
				validateApiVersion('Aura component', componentName, componentFiles.xmlFile, metaApiVersion)
			);
			
			errors.addAll(
				validateDependencyFromPackageVersions('Aura component', componentName, componentFiles.xmlFile, metaRoot)
			);
			
		}
		
		
		// loop through lwc components
		BundleHelper.forEachLWC(artifactsDir) { componentName, componentFiles, metaRoot, metaApiVersion -> 
			
			errors.addAll(
				validateDescriptorPresence('LWC component', componentName, componentFiles.xmlFile)
			);
			
			errors.addAll(
				validateApiVersion('LWC component', componentName, componentFiles.xmlFile, metaApiVersion)
			);
			
			errors.addAll(
				validateDependencyFromPackageVersions('LWC component', componentName, componentFiles.xmlFile, metaRoot)
			);
			
		}
		
		
		// loop through flows
		BundleHelper.forEachFlow(artifactsDir) { flowName, flowFile, flowRoot, Double apiVersion -> 
			
			errors.addAll(
				validateApiVersion('Flow', flowName, flowFile, apiVersion)
			);
			
		}
		
		
		return errors;
		
	}
	
	
	
	public String getName() {
		
		return "Api Version Validator";
		
	}
	
	
	// validate presence of descriptor file for component
	private List<String> validateDescriptorPresence(def artifactTypeLabel, def artifactName, def metaFile) {
		
		List<String> errors = [];
		
		if (!metaFile || !metaFile.exists()) {
			errors << "${artifactTypeLabel} '${artifactName}' does not have complementary metadata descriptor file ${metaFile && metaFile.name ? '"' + metaFile.name + '"' : ''}";
		}
		
		
		return errors;
		
	}
	
	
	
	// validate api version
	private List<String> validateApiVersion(def artifactTypeLabel, def artifactName, def metaFile, def metaApiVersion) {
		
		List<String> errors = [];
		
		if (
			// api version is applicable for artifact
			metaApiVersion != null 
			&& 
			// is not marked as exclusion
			!(BundleHelper.readFile(metaFile) =~ EXCLUDE_MARKER_REGEX)
		) {
			
			// error if older api version is in use
			if (this.minApiVersion && metaApiVersion < this.minApiVersion) {
				errors << "${artifactTypeLabel} '${artifactName}' is using older api version '${metaApiVersion}' while min allowed is '${minApiVersion}'";
			}
			
			// error if newer api version is in use
			if (this.maxApiVersion && metaApiVersion > this.maxApiVersion) {
				errors << "${artifactTypeLabel} '${artifactName}' is using newer api version '${metaApiVersion}' while max allowed is '${maxApiVersion}'";
			}
			
		}
		
		
		return errors;
		
	}
	
	
	
	// validate dependency from package versions
	private List<String> validateDependencyFromPackageVersions(def artifactTypeLabel, def artifactName, def metaFile, def metaRoot) {
		
		List<String> errors = [];
		
		// early exit - no metadata descriptor file at all
		if (!metaRoot) {
			return errors;
		}
		
		
		metaRoot.packageVersions?.each { packageVersion ->
			
			def namespace = packageVersion.namespace?.toString() ?: 'unknown';
			def majorNumber = packageVersion.majorNumber?.toString() ?: 'unknown';
			def minorNumber = packageVersion.minorNumber?.toString() ?: 'unknown';
			
			errors << "${artifactTypeLabel} '${artifactName}' has dependency specified from ${namespace} package version ${majorNumber}.${minorNumber}";
			
		}
		
		
		return errors;
		
	}
	
	
}