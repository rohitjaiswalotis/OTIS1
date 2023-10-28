package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class PermissionSetValidator implements Validator {
	
	private File permissionSetsDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public PermissionSetValidator(File permissionSetsDir, String customScope) {
		
		this(permissionSetsDir, customScope, null);
		
	}
	
	
	public PermissionSetValidator(File permissionSetsDir, String customScope, def exclusions) {
		
		this.permissionSetsDir = permissionSetsDir;
		this.customPrefix = this.getCustomPrefix(customScope);
		
		this.exclusions = new TreeSet<String>(String.CASE_INSENSITIVE_ORDER);
		
		if (exclusions) {
			this.exclusions.addAll(exclusions);
		}
		
	}
	
	
	public Boolean skip() {
		
		return (
			this.exclusions 
			&& 
			"*" in this.exclusions
		);
		
	}
	
	
	public List<String> validate() {
		
		if (!this.customPrefix) {
			return;
		}
		
		String normalizedCustomPrefix = BundleHelper.normalize(this.customPrefix);
		List<String> errors = [];
		
		
		// loop through permission sets
		BundleHelper.forEachPermissionSet(this.permissionSetsDir) { permissionSetName, permissionSetRoot ->
			
			def normalizedPermissionSetName = BundleHelper.normalize(permissionSetName) - ~/^\./;
			
			// ignore excluded permission sets
			if (normalizedPermissionSetName in this.exclusions) {
				return;
			}
			
			// enforce description to be populated
			if (!permissionSetRoot?.description?.toString()) {
				errors << "Permission Set '${permissionSetName}' should have description populated.";	
			}
			
			// ignore correctly prefixed permission sets
			if (!normalizedPermissionSetName.startsWith(normalizedCustomPrefix)) {
				errors << "Permission Set '${permissionSetName}' should start with '${this.customPrefix}' custom prefix."
			}
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Permission Sets Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return (
			customScope 
			? 
				customScope.replaceAll("_+\$", "") + '_' 
				: 
				customScope
		);
		
	}
	
	
}