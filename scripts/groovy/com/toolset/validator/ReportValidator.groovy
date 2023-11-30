package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class ReportValidator implements Validator {
	
	private File reportsDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public ReportValidator(File reportsDir, String customScope) {
		
		this(reportsDir, customScope, null);
		
	}
	
	
	public ReportValidator(File reportsDir, String customScope, def exclusions) {
		
		this.reportsDir = reportsDir;
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
		BundleHelper.forEachReportFolder(this.reportsDir) { reportFolderName, reportFolderRoot ->
			
			def normalizedFolderName = BundleHelper.normalize(reportFolderName) - ~/^\./;
			
			
			reportFolderRoot.folderShares.each { folderShareRoot ->
				
				def sharedToName = folderShareRoot.sharedTo.toString();
				def sharedToType = folderShareRoot.sharedToType.toString();
				
				if (
					BundleHelper.isNormalizedEquals(sharedToType, "User")
					&&
					sharedToName.contains('@')
				) {
					errors << "Report Folder '${reportFolderName}' should not be shared with hardcoded username: '${sharedToName}'."
				}
				
			}
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Reports Validator";
		
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