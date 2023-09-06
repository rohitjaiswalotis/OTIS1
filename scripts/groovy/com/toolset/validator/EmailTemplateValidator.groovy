package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class EmailTemplateValidator implements Validator {
	
	private File emailTemplatesDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public EmailTemplateValidator(File emailTemplatesDir, String customScope) {
		
		this(emailTemplatesDir, customScope, null);
		
	}
	
	
	public EmailTemplateValidator(File emailTemplatesDir, String customScope, def exclusions) {
		
		this.emailTemplatesDir = emailTemplatesDir;
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
		
		
		// loop through email templates
		BundleHelper.forEachEmailTemplate(this.emailTemplatesDir) { emailTemplateName, emailTemplateFile ->
			
			def normalizedEmailTemplateName = BundleHelper.normalize(emailTemplateName) - ~/^\./;
			
			if (
				// ignore excluded email template
				normalizedEmailTemplateName in this.exclusions 
				|| 
				// ignore correctly prefixed email templates
				normalizedEmailTemplateName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "Email Template '${emailTemplateName}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		// loop through email folders
		BundleHelper.forEachEmailFolder(this.emailTemplatesDir) { emailFolderName, emailFolderRoot ->
			
			def normalizedEmailFolderName = BundleHelper.normalize(emailFolderName) - ~/^\./;
			
			if (
				// ignore excluded email folder
				normalizedEmailFolderName in this.exclusions 
				|| 
				// ignore correctly prefixed email folders
				normalizedEmailFolderName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "Email Folder '${emailFolderName}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Email Templates Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "") + '_';
		
	}
	
	
}