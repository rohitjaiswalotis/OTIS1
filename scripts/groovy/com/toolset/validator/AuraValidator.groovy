package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class AuraValidator implements Validator {
	
	private File auraDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public AuraValidator(File auraDir, String customScope) {
		
		this(auraDir, customScope, null);
		
	}
	
	
	public AuraValidator(File auraDir, String customScope, def exclusions) {
		
		this.auraDir = auraDir;
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
		
		
		// loop through aura components
		BundleHelper.forEachAura(this.auraDir) { auraName, filesRegistry ->
			
			def normalizedAuraName = BundleHelper.normalize(auraName) - ~/^\./;
			
			if (
				// ignore excluded aura components
				normalizedAuraName in this.exclusions 
				|| 
				// ignore correctly prefixed aura components
				normalizedAuraName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "Aura Component '${auraName}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Aura Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "") + '_';
		
	}
	
	
}