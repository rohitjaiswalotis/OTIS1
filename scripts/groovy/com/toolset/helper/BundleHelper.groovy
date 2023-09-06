package com.toolset.helper;

import java.lang.System;
import groovy.io.FileType;
import groovy.xml.XmlSlurper;

import com.toolset.helper.ObjectHelper;


public class BundleHelper {
	
	// default encoding
	public static final String DEFAULT_FILE_ENCODING = "UTF-8";
	
	
	// file extensions
	private static final String FILE_EXTENSION_HTML = 'html';
	private static final String FILE_EXTENSION_CSS = 'css';
	private static final String FILE_EXTENSION_JS = 'js';
	private static final String FILE_EXTENSION_CMP = 'cmp';
	private static final String FILE_EXTENSION_DESIGN = 'design';
	private static final String FILE_EXTENSION_XML = 'xml';
	private static final String FILE_EXTENSION_AURA = 'cmp-meta.xml';
	private static final String FILE_EXTENSION_LWC = 'js-meta.xml';
	private static final String FILE_EXTENSION_OBJECT = 'object-meta.xml';
	private static final String FILE_EXTENSION_FIELD = 'field-meta.xml';
	private static final String FILE_EXTENSION_PERMISSIONSET = 'permissionset-meta.xml';
	private static final String FILE_EXTENSION_PERMISSIONSET_GROUP = 'permissionsetgroup';
	private static final String FILE_EXTENSION_PROFILE = 'profile';
	private static final String FILE_EXTENSION_CUSTOM_PERMISSION = 'customPermission-meta.xml';
	private static final String FILE_EXTENSION_CLASS = 'cls';
	private static final String FILE_EXTENSION_TRIGGER = 'trigger';
	private static final String FILE_EXTENSION_CUSTOM_METADATA = 'md';
	private static final String FILE_EXTENSION_TAB = 'tab';
	private static final String FILE_EXTENSION_QUICK_ACTION = 'quickAction';
	private static final String FILE_EXTENSION_FLEXI_PAGE = 'flexipage-meta.xml';
	private static final String FILE_EXTENSION_VISUAL_FORCE_PAGE = 'page';
	private static final String FILE_EXTENSION_VISUAL_FORCE_COMPONENT = 'component';
	private static final String FILE_EXTENSION_NAMED_CREDENTIAL = 'namedCredential';
	private static final String FILE_EXTENSION_CONNECTED_APP = 'connectedApp';
	private static final String FILE_EXTENSION_TRANSLATION = 'translation';
	private static final String FILE_EXTENSION_GLOBAL_VALUESET = 'globalValueSet';
	private static final String FILE_EXTENSION_GLOBAL_VALUESET_TRANSLATION = 'globalValueSetTranslation';
	private static final String FILE_EXTENSION_STANDARD_VALUESET = 'standardValueSet';
	private static final String FILE_EXTENSION_QUEUE = 'queue';
	private static final String FILE_EXTENSION_LABELS = 'labels-meta.xml';
	private static final String FILE_EXTENSION_EMAIL_TEMPLATE = 'email';
	private static final String FILE_EXTENSION_EMAIL_FOLDER = 'emailFolder-meta.xml';
	
	public static final String FILE_SUFFIX_META_DESCRIPTOR = "-meta.xml";
	
	public static final String AURA_ENABLED_ANNOTATION = "@AuraEnabled";
	public static final def AURA_ENABLED_REGEX = /(?i)${AURA_ENABLED_ANNOTATION}\s*(\([^\)]*\))?[^{;(=]+\(/;
	
	public static final String IS_TEST_ANNOTATION = "@IsTest";
	public static final def IS_TEST_REGEX = /(?im)(^|\s+)${IS_TEST_ANNOTATION}\s*(\(|$)/;
	
	public static final String REST_RESOURCE_ANNOTATION = "@RestResource";
	public static final def REST_RESOURCE_REGEX = /(?i)${REST_RESOURCE_ANNOTATION}\s*\(\s*urlMapping\s*=\s*'([^']+)'\s*\)/;
	
	
	// field types
	public static final String FIELD_TYPE_PICKLIST = 'Picklist';
	public static final String FIELD_TYPE_MULTISELECT_PICKLIST = 'MultiselectPicklist';
	public static final String FIELD_TYPE_LOOKUP = 'Lookup';
	public static final String FIELD_TYPE_MASTER_DETAIL = 'MasterDetail';
	
	// field limits
	public static final Integer FIELDS_TOTAL_LIMIT = 500;
	public static final Integer FIELDS_UNIQUE_LIMIT = 25;
	public static final Integer FIELDS_EXTERNAL_ID_LIMIT = 25;
	public static final Integer FIELDS_LOOKUP_LIMIT = 38;
	public static final Integer FIELDS_MASTER_DETAIL_LIMIT = 2;
	public static final Integer FIELDS_FORMULA_LIMIT = 10;
	
	
	
	// loop through objects
	public static void forEachObject(File objectsDir, Closure eachObjectClosure) {
		
		if (!objectsDir.exists()) {
			return;
		}
		
		objectsDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_OBJECT}(\..*)?/) { objectFile ->
			
			// evaluate object name based on file name - just by removing file extension
			def objectName = objectFile.name.substring(0, objectFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_OBJECT.toLowerCase()}"));
			
			// parse object xml
			def objectRoot = new XmlSlurper().parseText(readFile(objectFile));
			
			// callback to closure with params
			eachObjectClosure.call(
				objectName, 
				objectRoot,
				objectFile
			);
			
		}
		
	}
	
	
	
	// loop through standard objects
	public static void forEachStandardObject(File objectsDir, Closure eachStandardObjectClosure) {
		
		forEachObject(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (ObjectHelper.isStandardObject(objectName)) {
				
				// callback to closure with params
				eachStandardObjectClosure.call(
					objectName, 
					objectRoot,
					objectFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through custom objects files
	public static void forEachCustomObject(File objectsDir, Closure eachCustomObjectClosure) {
		
		forEachObject(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (
				ObjectHelper.isCustomObject(objectName)
				&&
				objectRoot.customSettingsType.isEmpty()
			) {
				
				// callback to closure with params
				eachCustomObjectClosure.call(
					objectName, 
					objectRoot,
					objectFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through local custom objects files, i.e. without namespace
	public static void forEachLocalCustomObject(File objectsDir, Closure eachLocalCustomObjectClosure) {
		
		forEachCustomObject(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (ObjectHelper.hasObjectNamespace(objectName)) {
				return;
			}
			
			// callback to closure with params
			eachLocalCustomObjectClosure.call(
				objectName, 
				objectRoot,
				objectFile
			);
			
		}
		
	}
	
	
	
	// loop through custom settings files
	public static void forEachCustomSetting(File objectsDir, Closure eachCustomSettingClosure) {
		
		forEachObject(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (
				ObjectHelper.isCustomObject(objectName)
				&&
				!objectRoot.customSettingsType.isEmpty()
			) {
				
				eachCustomSettingClosure.call(
					objectName,
					objectRoot,
					objectFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through local custom settings files, i.e. without namespace
	public static void forEachLocalCustomSetting(File objectsDir, Closure eachLocalCustomSettingClosure) {
		
		forEachCustomSetting(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (ObjectHelper.hasObjectNamespace(objectName)) {
				return;
			}
			
			// callback to closure with params
			eachLocalCustomSettingClosure.call(
				objectName, 
				objectRoot,
				objectFile
			);
			
		}
		
	}
	
	
	
	// loop through custom metadata files
	public static void forEachCustomMetadata(File objectsDir, Closure eachCustomMetadataClosure) {
		
		forEachObject(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (ObjectHelper.isCustomMetadata(objectName)) {
				
				// callback to closure with params
				eachCustomMetadataClosure.call(
					objectName, 
					objectRoot,
					objectFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through local custom metadata files, i.e. without namespace
	public static void forEachLocalCustomMetadata(File objectsDir, Closure eachLocalCustomMetadataClosure) {
		
		forEachCustomMetadata(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (ObjectHelper.hasObjectNamespace(objectName)) {
				return;
			}
			
			// callback to closure with params
			eachLocalCustomMetadataClosure.call(
				objectName, 
				objectRoot,
				objectFile
			);
			
		}
		
	}
	
	
	
	// loop through platform events files
	public static void forEachPlatformEvent(File objectsDir, Closure eachPlatformEventClosure) {
		
		forEachObject(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (ObjectHelper.isPlatformEvent(objectName)) {
				
				// callback to closure with params
				eachPlatformEventClosure.call(
					objectName, 
					objectRoot,
					objectFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through local platform events files, i.e. without namespace
	public static void forEachLocalPlatformEvent(File objectsDir, Closure eachLocalPlatformEventClosure) {
		
		forEachPlatformEvent(objectsDir) { objectName, objectRoot, objectFile -> 
			
			if (ObjectHelper.hasObjectNamespace(objectName)) {
				return;
			}
			
			// callback to closure with params
			eachLocalPlatformEventClosure.call(
				objectName, 
				objectRoot,
				objectFile
			);
			
		}
		
	}
	
	
	
	// loop through fields
	public static void forEachField(File fieldsDir, Closure eachFieldClosure) {
		
		if (!fieldsDir.exists()) {
			return;
		}
		
		fieldsDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_FIELD}(\..*)?/) { fieldFile ->
			
			// evaluate field name based on file name - just by removing file extension
			def fieldName = fieldFile.name.substring(0, fieldFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_FIELD.toLowerCase()}"));
			
			// parse object xml
			def fieldRoot = new XmlSlurper().parseText(readFile(fieldFile));
			
			// callback to closure with params
			eachFieldClosure.call(
				fieldName, 
				fieldRoot,
				fieldFile
			);
			
		}
		
	}
	
	
	
	// loop through standard fields
	public static void forEachStandardField(File fieldsDir, Closure eachStandardFieldClosure) {
		
		forEachField(fieldsDir) { fieldName, fieldRoot, fieldFile -> 
			
			if (ObjectHelper.isStandardField(fieldRoot.fullName.toString())) {
				
				// callback to closure with params
				eachStandardFieldClosure.call(
					fieldName, 
					fieldRoot,
					fieldFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through custom fields
	public static void forEachCustomField(File fieldsDir, Closure eachCustomFieldClosure) {
		
		forEachField(fieldsDir) { fieldName, fieldRoot, fieldFile -> 
			
			if (ObjectHelper.isCustomField(fieldRoot.fullName.toString())) {
				
				// callback to closure with params
				eachCustomFieldClosure.call(
					fieldName, 
					fieldRoot,
					fieldFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through required fields
	public static void forEachRequiredField(File fieldsDir, Closure eachRequiredFieldClosure) {
		
		forEachField(fieldsDir) { fieldName, fieldRoot, fieldFile ->
			
			if (fieldRoot?.required?.toString()?.toBoolean() == true) {
				
				eachRequiredFieldClosure.call(
					fieldName, 
					fieldRoot, 
					fieldFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through picklist fields
	public static void forEachPicklist(File fieldsDir, Closure eachPicklistClosure) {
		
		forEachField(fieldsDir) { fieldName, fieldRoot, fieldFile ->
			
			if (isFieldPicklist(fieldRoot)) {
				
				eachPicklistClosure.call(
					fieldName, 
					fieldRoot, 
					fieldFile
				)
				
			}
			
		}
		
	}
	
	
	
	// loop through restricted picklist fields
	public static void forEachRestrictedPicklist(File fieldsDir, Closure eachRestrictedPicklistClosure) {
		
		forEachPicklist(fieldsDir) { fieldName, fieldRoot, fieldFile ->
			
			if (isFieldRestrictedPicklist(fieldRoot)) {
				
				eachRestrictedPicklistClosure.call(
					fieldName, 
					fieldRoot, 
					fieldFile
				)
				
			}
			
		}
		
	}
	
	
	
	// loop through picklist options
	public static void forEachPicklistOption(def fieldRoot, Closure eachPicklistOptionClosure) {
		
		fieldRoot.valueSet?.valueSetDefinition?.value?.each { option ->
			
			eachPicklistOptionClosure.call(
				option
			);
			
		}
		
	}
	
	
	
	// loop through apex classes
	public static void forEachClass(File classesDir, Closure eachClassClosure) {
		
		if (!classesDir.exists()) {
			return;
		}
		
		classesDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_CLASS}(\..*)?/) { classFile ->
			
			// evaluate class name based on file name - just by removing file extension
			def className = classFile.name.substring(0, classFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_CLASS.toLowerCase()}"));
			
			def closureParamsCount = eachClassClosure.parameterTypes.size();
			
			if (closureParamsCount == 2) {
				
				eachClassClosure.call(
					className, 
					classFile
				);
				
				return;
				
			}
			
			
			// parse metadata descriptor file and api version from its content
			def (metaName, metaFile, metaRoot) = getDescriptorForArtifact(classFile);
			def apiVersion = metaRoot == null ? null : getApiVersionFromDescriptor(metaRoot);
			
				
			if (closureParamsCount == 6) {
				
				eachClassClosure.call(
					className, 
					classFile,
					metaName,
					metaFile, 
					metaRoot,
					apiVersion
				);
				
				return;
				
			}
			
		}
		
	}
	
	
	
	// loop through @AuraEnabled apex classes
	public static void forEachAuraClass(File classesDir, Closure eachAuraClassClosure) {
		
		forEachClass(classesDir) { className, classFile -> 
			
			if (readFile(classFile) =~ AURA_ENABLED_REGEX) {
				
				eachAuraClassClosure.call(
					className,
					classFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through @RestResource apex classes
	public static void forEachRestClass(File classesDir, Closure eachRestClassClosure) {
		
		forEachClass(classesDir) { className, classFile -> 
			
			def restResourceMatcher = readFile(classFile) =~ REST_RESOURCE_REGEX;
			
			if (restResourceMatcher) {
				
				def urlMapping = restResourceMatcher[0][1];
				
				eachRestClassClosure.call(
					className,
					classFile,
					urlMapping
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through @IsTest apex classes
	public static void forEachTestClass(File classesDir, Closure eachTestClassClosure) {
		
		forEachClass(classesDir) { className, classFile -> 
			
			if (readFile(classFile) =~ IS_TEST_REGEX) {
				
				eachTestClassClosure.call(
					className,
					classFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through global apex classes
	public static void forEachGlobalClass(File classesDir, Closure eachGlobalClassClosure) {
		
		forEachClass(classesDir) { className, classFile -> 
			
			if (readFile(classFile) =~ /(?i)(^|\s)global\s+(\w+\s+)*?class\s+${className}\s+/) {
				
				eachGlobalClassClosure.call(
					className,
					classFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through apex triggers
	public static void forEachTrigger(File triggersDir, Closure eachTriggerClosure) {
		
		if (!triggersDir.exists()) {
			return;
		}
		
		triggersDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_TRIGGER}(\..*)?/) { triggerFile ->
			
			// evaluate trigger name based on file name - just by removing file extension
			def triggerName = triggerFile.name.substring(0, triggerFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_TRIGGER.toLowerCase()}"));
			
			// read trigger body
			def triggerBody = readFile(triggerFile);
			
			// parse trigger body to get object
			def matcher = ( triggerBody =~ /(?imx)^\s*trigger\s+${triggerName}\s+on\s+(.+?)\s*\(/ );
			
			def triggerObject = matcher ? matcher[0][1] : null;
			
			if (triggerObject == null) {
				System.err.println "WARNING: cannot parse trigger object from file ${triggerFile.name}";
			}
			
			
			def closureParamsCount = eachTriggerClosure.parameterTypes.size();
			
			
			if (closureParamsCount == 3) {
				
				eachTriggerClosure.call(
					triggerName, 
					triggerFile,
					triggerObject
				);
				
				return;
				
			}
			
			
			// parse metadata descriptor file and api version from its content
			def (metaName, metaFile, metaRoot) = getDescriptorForArtifact(triggerFile);
			def apiVersion = metaRoot == null ? null : getApiVersionFromDescriptor(metaRoot);
			
			
			if (closureParamsCount == 6) {
				
				eachTriggerClosure.call(
					triggerName, 
					triggerFile,
					triggerObject,
					metaFile,
					metaRoot,
					apiVersion
				);
				
				return;
				
			}
			
		}
		
	}
	
	
	
	// loop through lwc components
	public static void forEachLWC(File componentsDir, Closure eachComponentClosure) {
		
		if (!componentsDir.exists()) {
			return;
		}
		
		// loop through lwc components directories
		componentsDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_LWC}(\..*)?/) { lwcFile ->
			
			def componentDir = lwcFile.getParentFile();
			
			// consider only directories starting with letter
			if ( !(componentDir.name =~ /(?i)^[a-z]+/) ) {
				return;
			}
			
			def filesRegistry = [:];
			
			
			// loop through component's files
			componentDir.eachFile(FileType.FILES) { componentFile -> 
				
				def lastDotInFileNameIndex = componentFile.name.lastIndexOf('.');
				
				// move to next file
				if (lastDotInFileNameIndex == -1) {
					return;
				}
				
				
				// extract file extension
				def fileExtension = componentFile.name.substring(lastDotInFileNameIndex + 1);
				def fileName = componentFile.name.substring(0, lastDotInFileNameIndex);
				
				
				// catch html file
				if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_HTML)) {
					
					// main component css file
					if (fileName.equalsIgnoreCase(componentDir.name)) {
						filesRegistry.htmlFile = componentFile;
					}
					
					filesRegistry.htmlFiles = filesRegistry.htmlFiles ?: [];
					filesRegistry.htmlFiles << componentFile;
					
					
				// catch css file
				} else if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_CSS)) {
					
					// main component css file
					if (fileName.equalsIgnoreCase(componentDir.name)) {
						filesRegistry.cssFile = componentFile;
					}
					
					filesRegistry.cssFiles = filesRegistry.cssFiles ?: [];
					filesRegistry.cssFiles << componentFile;
					
					
				// catch js file
				} else if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_JS)) {
					
					// main component js file
					if (fileName.equalsIgnoreCase(componentDir.name)) {
						filesRegistry.jsFile = componentFile;
					}
					
					filesRegistry.jsFiles = filesRegistry.jsFiles ?: [];
					filesRegistry.jsFiles << componentFile;
					
					
				// catch xml file
				} else if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_XML)) {
					
					filesRegistry.xmlFile = componentFile;
					
				}
				
			}
			
			
			def closureParamsCount = eachComponentClosure.parameterTypes.size();
			
			
			if (closureParamsCount == 2) {
				
				eachComponentClosure.call(
					componentDir.name,
					filesRegistry
				);
				
				return;
				
			}
			
			
			// parse metadata descriptor file and api version from its content
			def (metaName, metaFile, metaRoot) = getDescriptorForArtifact(filesRegistry.xmlFile);
			def apiVersion = metaRoot == null ? null : getApiVersionFromDescriptor(metaRoot);
			
			
			if (closureParamsCount == 4) {
				
				eachComponentClosure.call(
					componentDir.name,
					filesRegistry,
					metaRoot,
					apiVersion
				);
				
				return;
				
			}
			
		}
		
	}
	
	
	
	// loop through aura components
	public static void forEachAura(File componentsDir, Closure eachComponentClosure) {
		
		if (!componentsDir.exists()) {
			return;
		}
		
		// loop through aura components directories
		componentsDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_AURA}(\..*)?/) { auraFile ->
			
			def componentDir = auraFile.getParentFile();
			
			// consider only directories starting with letter
			if (! (componentDir.name =~ /(?i)^[a-z]+/) ) {
				return;
			}
			
			def filesRegistry = [:];
			
			
			// loop through component's files
			componentDir.eachFile(FileType.FILES) { componentFile -> 
				
				def lastDotInFileNameIndex = componentFile.name.lastIndexOf('.');
				
				// move to next file
				if (lastDotInFileNameIndex == -1) {
					return;
				}
				
				
				// extract file extension
				def fileExtension = componentFile.name.substring(lastDotInFileNameIndex + 1);
				def fileName = componentFile.name.substring(0, lastDotInFileNameIndex);
				
				
				// catch component file
				if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_CMP)) {
					
					filesRegistry.componentFile = componentFile;
					
				// catch css file
				} else if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_CSS)) {
					
					filesRegistry.cssFile = componentFile;
					
				// catch js file
				} else if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_JS)) {
					
					if (fileName.toLowerCase().endsWith('Helper'.toLowerCase())) {
						
						filesRegistry.helperFile = componentFile;
						
					} else if (fileName.toLowerCase().endsWith('Controller'.toLowerCase())) {
						
						filesRegistry.controllerFile = componentFile;
						
					}
					
				// catch design file
				} else if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_DESIGN)) {
					
					filesRegistry.designFile = componentFile;
					
				// catch xml file
				} else if (fileExtension.equalsIgnoreCase(FILE_EXTENSION_XML)) {
					
					filesRegistry.xmlFile = componentFile;
					
				}
				
			}
			
			
			def closureParamsCount = eachComponentClosure.parameterTypes.size();
			
			
			if (closureParamsCount == 2) {
				
				eachComponentClosure.call(
					componentDir.name,
					filesRegistry
				);
				
				return;
				
			}
			
			
			// parse metadata descriptor file and api version from its content
			def (metaName, metaFile, metaRoot) = getDescriptorForArtifact(filesRegistry.xmlFile);
			def apiVersion = metaRoot == null ? null : getApiVersionFromDescriptor(metaRoot);
			
			
			if (closureParamsCount == 4) {
				
				eachComponentClosure.call(
					componentDir.name,
					filesRegistry,
					metaRoot,
					apiVersion
				);
				
				return;
				
			}
			
		}
		
	}
	
	
	
	// loop through visual force pages
	public static void forEachVisualForcePage(File visualForcePagesDir, Closure eachVisualForcePageClosure) {
		
		if (!visualForcePagesDir.exists()) {
			return;
		}
		
		visualForcePagesDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_VISUAL_FORCE_PAGE}(\..*)?/) { visualForcePageFile ->
			
			// evaluate visual force page name based on file name - just by removing file extension
			def visualForcePageName = visualForcePageFile.name.substring(0, visualForcePageFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_VISUAL_FORCE_PAGE.toLowerCase()}"));
			
			
			def closureParamsCount = eachVisualForcePageClosure.parameterTypes.size();
			
			
			if (closureParamsCount == 2) {
				
				eachVisualForcePageClosure.call(
					visualForcePageName, 
					visualForcePageFile
				);
				
				return;
				
			}
			
			
			// parse metadata descriptor file and api version from its content
			def (metaName, metaFile, metaRoot) = getDescriptorForArtifact(visualForcePageFile);
			def apiVersion = metaRoot == null ? null : getApiVersionFromDescriptor(metaRoot);
			
			
			if (closureParamsCount == 5) {
				
				eachVisualForcePageClosure.call(
					visualForcePageName, 
					visualForcePageFile,
					metaFile,
					metaRoot,
					apiVersion
				);
				
				return;
				
			}
			
		}
		
	}
	
	
	
	// loop through flexi pages
	public static void forEachFlexiPage(File flexiPagesDir, Closure eachFlexiPageClosure) {
		
		if (!flexiPagesDir.exists()) {
			return;
		}
		
		flexiPagesDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_FLEXI_PAGE}(\..*)?/) { flexiPageFile ->
			
			// evaluate flexi page name based on file name - just by removing file extension
			def flexiPageName = flexiPageFile.name.substring(0, flexiPageFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_FLEXI_PAGE.toLowerCase()}"));
			
			// callback to closure with params
			eachFlexiPageClosure.call(
				flexiPageName, 
				flexiPageFile
			);
			
		}
		
	}
	
	
	
	// loop through permission sets
	public static void forEachPermissionSet(File permissionSetsDir, Closure eachPermissionSetClosure) {
		
		if (!permissionSetsDir.exists()) {
			return;
		}
		
		permissionSetsDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_PERMISSIONSET}(\..*)?/) { permissionSetFile ->
			
			// evaluate permission set name based on file name - just by removing permission set extension
			def permissionSetName = permissionSetFile.name.substring(0, permissionSetFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_PERMISSIONSET.toLowerCase()}"));
			
			def permissionSetRoot = new XmlSlurper().parseText(readFile(permissionSetFile));
			
			// callback to closure with params
			eachPermissionSetClosure.call(
				permissionSetName, 
				permissionSetRoot
			);
			
		}
		
	}
	
	
	
	// loop through custom permissions
	public static void forEachCustomPermission(File customPermissionsDir, Closure eachCustomPermissionClosure) {
		
		if (!customPermissionsDir.exists()) {
			return;
		}
		
		customPermissionsDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_CUSTOM_PERMISSION}(\..*)?/) { customPermissionFile ->
			
			// evaluate custom permission name based on file name - just by removing custom permission extension
			def customPermissionName = customPermissionFile.name.substring(0, customPermissionFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_CUSTOM_PERMISSION.toLowerCase()}"));
			
			def customPermissionRoot = new XmlSlurper().parseText(readFile(customPermissionFile));
			
			// callback to closure with params
			eachCustomPermissionClosure.call(
				customPermissionName, 
				customPermissionRoot
			);
			
		}
		
	}
	
	
	
	// loop through custom labels
	public static void forEachCustomLabel(File labelsDir, Closure eachLabelClosure) {
		
		if (!labelsDir.exists()) {
			return;
		}
		
		labelsDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_LABELS}(\..*)?/) { labelFile ->
			
			// parse labels xml
			def labelsRoot = new XmlSlurper().parseText(readFile(labelFile));
			
			labelsRoot.labels.each { labelRoot ->
				
				// callback to closure with params
				eachLabelClosure.call(
					labelRoot.fullName.toString(), 
					labelRoot,
					labelFile
				);
				
			}
			
		}
		
	}
	
	
	
	// loop through apex classes
	public static void forEachEmailTemplate(File emailTemplatesDir, Closure eachEmailTemplateClosure) {
		
		if (!emailTemplatesDir.exists()) {
			return;
		}
		
		emailTemplatesDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_EMAIL_TEMPLATE}(\..*)?/) { emailTemplateFile ->
			
			// evaluate email template name based on file name - just by removing file extension
			def emailTemplateName = emailTemplateFile.name.substring(0, emailTemplateFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_EMAIL_TEMPLATE.toLowerCase()}"));
			
			def closureParamsCount = eachEmailTemplateClosure.parameterTypes.size();
			
			if (closureParamsCount == 2) {
				
				eachEmailTemplateClosure.call(
					emailTemplateName, 
					emailTemplateFile
				);
				
				return;
				
			}
			
			
			// parse metadata descriptor file and api version from its content
			def (metaName, metaFile, metaRoot) = getDescriptorForArtifact(emailTemplateFile);
			
			
			if (closureParamsCount == 5) {
				
				eachEmailTemplateClosure.call(
					emailTemplateName, 
					emailTemplateFile,
					metaName,
					metaFile, 
					metaRoot
				);
				
				return;
				
			}
			
		}
		
	}
	
	
	
	// loop through custom permissions
	public static void forEachEmailFolder(File emailFoldersDir, Closure eachEmailFolderClosure) {
		
		if (!emailFoldersDir.exists()) {
			return;
		}
		
		emailFoldersDir.traverse(type: FileType.FILES, nameFilter: ~/(?i).*\.${FILE_EXTENSION_EMAIL_FOLDER}(\..*)?/) { emailFolderFile ->
			
			// evaluate email folder name based on file name - just by removing email folder extension
			def emailFolderName = emailFolderFile.name.substring(0, emailFolderFile.name.toLowerCase().lastIndexOf(".${FILE_EXTENSION_EMAIL_FOLDER.toLowerCase()}"));
			
			def emailFolderRoot = new XmlSlurper().parseText(readFile(emailFolderFile));
			
			// callback to closure with params
			eachEmailFolderClosure.call(
				emailFolderName, 
				emailFolderRoot
			);
			
		}
		
	}
	
	
	
	// check whether field is a picklist
	public static Boolean isFieldPicklist(def fieldNode) {
		
		return (
			isNormalizedEquals(
				fieldNode.type.toString(), 
				FIELD_TYPE_PICKLIST
			)
			||
			isFieldMultiselectPicklist(fieldNode)
		);
		
	}
	
	
	
	// check whether field is a restricted picklist
	public static Boolean isFieldRestrictedPicklist(def fieldNode) {
		
		return (
			fieldNode?.valueSet?.restricted?.toString()?.toBoolean()
			==
			true
		);
		
	}
	
	
	
	// check whether field is a multiselect picklist
	public static Boolean isFieldMultiselectPicklist(def fieldNode) {
		
		return (
			isNormalizedEquals(
				fieldNode.type.toString(), 
				FIELD_TYPE_MULTISELECT_PICKLIST
			)
		);
		
	}
	
	
	
	public static String normalize(def source) {
		source?.toString()?.trim()?.toLowerCase();
	}
	
	
	
	public static Boolean isNormalizedEquals(def source, def target) {
		normalize(source) == normalize(target);
	}
	
	
	
	public static String readFile(def file, def encoding=DEFAULT_FILE_ENCODING) {
		
		return file.getText(encoding);
		
	}
	
	
	
	private static def getDescriptorForArtifact(def artifactFile) {
		
		if (artifactFile == null) {
			return [ null, null, null ];
		}
		
		
		def metaName = artifactFile.name + (artifactFile.name.endsWith(FILE_SUFFIX_META_DESCRIPTOR) ? '' : FILE_SUFFIX_META_DESCRIPTOR);
		def metaFile = new File(artifactFile.getParent(), metaName);
		
		def metaRoot = (
			metaFile.exists() 
			? 
				new XmlSlurper().parseText(metaFile.text) 
				: 
				null
		);
		
		
		return [ metaName, metaFile, metaRoot ];
		
	}
	
	
	
	private static Double getApiVersionFromDescriptor(def descriptorRoot) {
		
		def apiVersion = descriptorRoot.apiVersion?.toString();
		
		return apiVersion.isDouble() ? (apiVersion as Double) : null;
		
	}
	
}