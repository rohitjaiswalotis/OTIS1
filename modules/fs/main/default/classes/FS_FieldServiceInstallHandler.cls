/**
* Package install handler interface
*/
global interface FS_FieldServiceInstallHandler {
	
	void beforeInstall(Map<String, Object> context);
	void afterInstall(Map<String, Object> context);
	
	void beforeUpgrade(Map<String, Object> context);
	void afterUpgrade(Map<String, Object> context);
	
}