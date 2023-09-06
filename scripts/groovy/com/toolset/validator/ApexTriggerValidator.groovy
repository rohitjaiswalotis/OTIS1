package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class ApexTriggerValidator implements Validator {
	
	private File triggersDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public ApexTriggerValidator(File triggersDir, String customScope) {
		
		this(triggersDir, customScope, null);
		
	}
	
	
	public ApexTriggerValidator(File triggersDir, String customScope, def exclusions) {
		
		this.triggersDir = triggersDir;
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
		
		
		// loop through apex triggers
		BundleHelper.forEachTrigger(this.triggersDir) { triggerName, triggerFile, triggerObject ->
			
			def normalizedTriggerName = BundleHelper.normalize(triggerName) - ~/^\./;
			
			if (
				// ignore excluded triggers
				normalizedTriggerName in this.exclusions 
				|| 
				// ignore correctly prefixed triggers
				normalizedTriggerName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "Trigger '${triggerName}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Apex Triggers Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "") + '_';
		
	}
	
	
}