package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class FlexiPageValidator implements Validator {
	
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
		
		if (!this.customPrefix) {
			return;
		}
		
		String normalizedCustomPrefix = BundleHelper.normalize(this.customPrefix);
		List<String> errors = [];
		
		
		// loop through pages
		BundleHelper.forEachFlexiPage(this.flexiPagesDir) { flexiPageName, flexiPageFile ->
			
			def normalizedPageName = BundleHelper.normalize(flexiPageName) - ~/^\./;
			
			if (
				// ignore excluded pages
				normalizedPageName in this.exclusions 
				|| 
				// ignore correctly prefixed pages
				normalizedPageName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "Flexi Page '${flexiPageName}' should start with '${this.customPrefix}' custom prefix."
			
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