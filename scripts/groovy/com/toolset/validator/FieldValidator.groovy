package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class FieldValidator implements Validator {
	
	private File fieldsDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public FieldValidator(File fieldsDir, String customScope) {
		
		this(fieldsDir, customScope, null);
		
	}
	
	
	public FieldValidator(File fieldsDir, String customScope, def exclusions) {
		
		this.fieldsDir = fieldsDir;
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
		
		
		// loop through fields
		BundleHelper.forEachCustomField(this.fieldsDir) { fieldName, fieldRoot, fieldFile ->

			def objectName = fieldFile.getParentFile()?.getParentFile()?.name;
			def fullFieldName = null;
			
			if (objectName) {
				
				fullFieldName = objectName + '.' + fieldName - ~/^\./;
				def normalizedFullFieldName = BundleHelper.normalize(fullFieldName);
				
				// ignore excluded fields
				if (normalizedFullFieldName in this.exclusions) {
					return;
				}
				
			}
			
			
			// enforce description to be populated
			if (!fieldRoot?.description?.toString()) {
				errors << "Field '${fullFieldName ?: fieldName}' should have description populated.";
			}
			
			
			def normalizedFieldName = BundleHelper.normalize(fieldName) - ~/^\./;
			
			// enforce custom prefix for field
			if (!normalizedFieldName.startsWith(normalizedCustomPrefix)) {
				errors << "Field '${fullFieldName ?: fieldName}' should start with '${this.customPrefix}' custom prefix."
			}
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Custom Fields Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "") + '_';
		
	}
	
	
}