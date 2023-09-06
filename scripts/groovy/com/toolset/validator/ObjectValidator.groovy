package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class ObjectValidator implements Validator {
	
	private File objectsDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public ObjectValidator(File objectsDir, String customScope) {
		
		this(objectsDir, customScope, null);
		
	}
	
	
	public ObjectValidator(File objectsDir, String customScope, def exclusions) {
		
		this.objectsDir = objectsDir;
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
		
		
		// loop through objects (including custom settings, mdt, events etc.)
		BundleHelper.forEachObject(this.objectsDir) { objectName, objectRoot, objectFile ->
			
			def normalizedObjectName = BundleHelper.normalize(objectName) - ~/^\./;
			
			// skip standard objects and objects with namespace
			if (
				ObjectHelper.isStandardObject(normalizedObjectName)
				||
				ObjectHelper.hasObjectNamespace(normalizedObjectName)
			) {
				return;
			}
			
			// ignore excluded objects
			if (normalizedObjectName in this.exclusions) {
				return;
			}
			
			// enforce description to be populated
			if (!objectRoot?.description?.toString()) {
				errors << "Object '${objectName}' should have description populated.";
			}
			
			// enforce custom prefix for object name
			if (!normalizedObjectName.startsWith(normalizedCustomPrefix)) {
				errors << "Object '${objectName}' should start with '${this.customPrefix}' custom prefix."
			}
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Custom Objects Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "") + '_';
		
	}
	
	
}