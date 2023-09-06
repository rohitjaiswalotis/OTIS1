package com.toolset.validator;

import groovy.io.FileType;
import com.toolset.helper.ObjectHelper;
import com.toolset.helper.BundleHelper;
import com.toolset.validator.Validator;


public class ApexClassValidator implements Validator {
	
	private File classesDir;
	private String customPrefix;
	private Set<String> exclusions;
	
	
	
	public ApexClassValidator(File classesDir, String customScope) {
		
		this(classesDir, customScope, null);
		
	}
	
	
	public ApexClassValidator(File classesDir, String customScope, def exclusions) {
		
		this.classesDir = classesDir;
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
		
		
		// loop through apex classes
		BundleHelper.forEachClass(this.classesDir) { className, classFile ->
			
			def normalizedClassName = BundleHelper.normalize(className) - ~/^\./;
			
			if (
				// ignore excluded classes
				normalizedClassName in this.exclusions 
				|| 
				// ignore correctly prefixed classes
				normalizedClassName.startsWith(normalizedCustomPrefix)
			) {
				return;
			}
			
			errors << "Class '${className}' should start with '${this.customPrefix}' custom prefix."
			
		}
		
		
		return errors;
		
	}
	
	
	public String getName() {
		
		return "Apex Classes Validator";
		
	}
	
	
	private String getCustomPrefix(String customScope) {
		
		return customScope.replaceAll("_+\$", "") + '_';
		
	}
	
	
}