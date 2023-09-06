package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class VisualForcePageValidator implements Validator {
	
	private File pagesDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public VisualForcePageValidator(File pagesDir, String customScope) {
		
		this(pagesDir, customScope, null);
		
	}
	
	
	public VisualForcePageValidator(File pagesDir, String customScope, def exclusions) {
		
		this.pagesDir = pagesDir;
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
		BundleHelper.forEachVisualForcePage(this.pagesDir) { visualForcePageName, visualForcePageFile ->
			
			def normalizedPageName = BundleHelper.normalize(visualForcePageName) - ~/^\./;
			
			if (
				// ignore excluded pages
				normalizedPageName in this.exclusions 
				|| 
				// ignore correctly prefixed pages
				normalizedPageName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "VisualForce Page '${visualForcePageName}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "VisualForce Pages Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "") + '_';
		
	}
	
	
}