package com.toolset.validator;

interface Validator {
	
	String getName();
	
	Boolean skip();
	
	List<String> validate();
	
}