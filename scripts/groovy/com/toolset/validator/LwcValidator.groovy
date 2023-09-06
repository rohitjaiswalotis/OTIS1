package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class LwcValidator implements Validator {
	
	private File lwcDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public LwcValidator(File lwcDir, String customScope) {
		
		this(lwcDir, customScope, null);
		
	}
	
	
	public LwcValidator(File lwcDir, String customScope, def exclusions) {
		
		this.lwcDir = lwcDir;
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
		
		
		// loop through lwc components
		BundleHelper.forEachLWC(this.lwcDir) { lwcName, filesRegistry ->
			
			def normalizedLwcName = BundleHelper.normalize(lwcName) - ~/^\./;
			
			if (
				// ignore excluded lwc components
				normalizedLwcName in this.exclusions 
				|| 
				// ignore correctly prefixed lwc components
				normalizedLwcName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "LWC Component '${lwcName}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "LWC Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "").toLowerCase() + '_';
		
	}
	
	
}