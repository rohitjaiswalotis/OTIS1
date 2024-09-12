

Map<String, Object> context = new Map<String, Object>();


for (
	Object handler 
	:
	new InterfaceResolver().getAllImplementations(
		FS_FieldServiceInstallHandler.class.getName()
	)
) {
	
	((FS_FieldServiceInstallHandler)handler).afterInstall(
		context
	);
	
}

