package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class CustomLabelValidator implements Validator {
	
	private File labelsDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public CustomLabelValidator(File labelsDir, String customScope) {
		
		this(labelsDir, customScope, null);
		
	}
	
	
	public CustomLabelValidator(File labelsDir, String customScope, def exclusions) {
		
		this.labelsDir = labelsDir;
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
		
		
		// loop through labels
		BundleHelper.forEachCustomLabel(this.labelsDir) { labelFullName, labelRoot, labelFile ->
			
			def normalizedLabelName = BundleHelper.normalize(labelFullName);
			
			if (
				// ignore excluded labels
				normalizedLabelName in this.exclusions 
				|| 
				// ignore correctly prefixed labels
				normalizedLabelName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "Custom Label '${labelFullName}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Custom Label Validator";
		
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