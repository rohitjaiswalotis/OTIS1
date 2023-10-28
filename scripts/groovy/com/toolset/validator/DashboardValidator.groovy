package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class DashboardValidator implements Validator {
	
	private File dashboardsDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public DashboardValidator(File dashboardsDir, String customScope) {
		
		this(dashboardsDir, customScope, null);
		
	}
	
	
	public DashboardValidator(File dashboardsDir, String customScope, def exclusions) {
		
		this.dashboardsDir = dashboardsDir;
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
		
		String normalizedCustomPrefix = BundleHelper.normalize(this.customPrefix);
		List<String> errors = [];
		
		
		// loop through folders
		BundleHelper.forEachDashboardFolder(this.dashboardsDir) { dashboardFolderName, dashboardFolderRoot ->
			
			def normalizedFolderName = BundleHelper.normalize(dashboardFolderName) - ~/^\./;
			
			
			dashboardFolderRoot.folderShares.each { folderShareRoot ->
				
				def sharedToName = folderShareRoot.sharedTo.toString();
				def sharedToType = folderShareRoot.sharedToType.toString();
				
				if (
					BundleHelper.isNormalizedEquals(sharedToType, "User")
					&&
					sharedToName.contains('@')
				) {
					errors << "Dashboard Folder '${dashboardFolderName}' should not be shared with hardcoded username: '${sharedToName}'."
				}
				
			}
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Dashboards Validator";
		
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