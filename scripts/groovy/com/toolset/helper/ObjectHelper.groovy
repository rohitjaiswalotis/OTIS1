package com.toolset.helper;


public class ObjectHelper {
	
	public static final String DOUBLE_UNDERSCORE = '__';
	public static final String CUSTOM_OBJECT_SUFFIX = DOUBLE_UNDERSCORE + 'c';
	public static final String CUSTOM_METADATA_SUFFIX = DOUBLE_UNDERSCORE + 'mdt';
	public static final String PLATFORM_EVENT_SUFFIX = DOUBLE_UNDERSCORE + 'e';
	
	
	
	public static Boolean isCustomField(String fieldName) {
		
		return fieldName.contains(DOUBLE_UNDERSCORE);
		
	}
	
	
	public static Boolean isStandardField(String fieldName) {
		
		return !fieldName.contains(DOUBLE_UNDERSCORE);
		
	}
	
	
	public static Boolean isCustomObject(String objectName) {
		
		return objectName.toLowerCase().endsWith(CUSTOM_OBJECT_SUFFIX);
		
	}
	
	
	public static Boolean isStandardObject(String objectName) {
		
		return !objectName.contains(DOUBLE_UNDERSCORE);
		
	}
	
	
	public static Boolean isCustomMetadata(String objectName) {
		
		return objectName.toLowerCase().endsWith(CUSTOM_METADATA_SUFFIX);
		
	}
	
	
	public static Boolean isPlatformEvent(String objectName) {
		
		return objectName.toLowerCase().endsWith(PLATFORM_EVENT_SUFFIX);
		
	}
	
	
	public static Boolean hasObjectNamespace(String objectName) {
		
		return objectName.count(DOUBLE_UNDERSCORE) > 1;
		
	}
	
	
}

