package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class CustomPermissionValidator implements Validator {
	
	private File permissionsDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public CustomPermissionValidator(File permissionsDir, String customScope) {
		
		this(permissionsDir, customScope, null);
		
	}
	
	
	public CustomPermissionValidator(File permissionsDir, String customScope, def exclusions) {
		
		this.permissionsDir = permissionsDir;
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
		BundleHelper.forEachCustomPermission(this.permissionsDir) { customPermissionName, customPermissionRoot ->
			
			def normalizedCustomPermissionName = BundleHelper.normalize(customPermissionName) - ~/^\./;
			
			// ignore excluded custom permissions
			if (normalizedCustomPermissionName in this.exclusions) {
				return;
			}
			
			// enforce description to be populated
			if (!customPermissionRoot?.description?.toString()) {
				errors << "Custom Permission '${customPermissionName}' should have description populated.";	
			}
			
			// ignore correctly prefixed permission sets
			if (!normalizedCustomPermissionName.startsWith(normalizedCustomPrefix)) {
				errors << "Custom Permission '${customPermissionName}' should start with '${this.customPrefix}' custom prefix."
			}
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Custom Permissions Validator";
		
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