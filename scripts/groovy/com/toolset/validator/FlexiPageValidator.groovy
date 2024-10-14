package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class FlexiPageValidator implements Validator {
	
	//public static final def NOT_SUPPORTED_SYNTAX_MARKER_REGEX = /(?i)<\s*value\s*>@@@/;
	public static final def NOT_SUPPORTED_SYNTAX_MARKER_REGEX = null;
	
	private File flexiPagesDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public FlexiPageValidator(File flexiPagesDir, String customScope) {
		
		this(flexiPagesDir, customScope, null);
		
	}
	
	
	public FlexiPageValidator(File flexiPagesDir, String customScope, def exclusions) {
		
		this.flexiPagesDir = flexiPagesDir;
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
		
		
		// loop through pages
		BundleHelper.forEachFlexiPage(this.flexiPagesDir) { flexiPageName, flexiPageFile ->
			
			def normalizedPageName = BundleHelper.normalize(flexiPageName) - ~/^\./;
			
			// check if page is prefixed
			if (normalizedCustomPrefix) {
				
				if (
					// page is not prefixed
					!
					normalizedPageName.startsWith(normalizedCustomPrefix)
					&&
					// page is not among excluded from validation
					! 
					(normalizedPageName in this.exclusions) 

				) {
					errors << "Flexi Page '${flexiPageName}' should start with '${this.customPrefix}' custom prefix.";
				}
				
			}
			
			
			// check if page contains not supported syntax
			if (NOT_SUPPORTED_SYNTAX_MARKER_REGEX) {
				
				if (
					BundleHelper.readFile(flexiPageFile) 
					=~ 
					NOT_SUPPORTED_SYNTAX_MARKER_REGEX
				) {
					errors << "Flexi Page '${flexiPageName}' contains unsupported syntax caught by the regex: ${NOT_SUPPORTED_SYNTAX_MARKER_REGEX}";
				}
				
			}
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Flexi Pages Validator";
		
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