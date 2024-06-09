/**
* Test class for Field Service package install handler.
*/
@IsTest
public inherited sharing class FS_FieldServiceInstallHandlerImplTest {
	
	
	@isTest
	static void basic() {
		
		FS_FieldServiceInstallHandler installHandler = new FS_FieldServiceInstallHandlerImpl();
		
		Map<String, Object> context = new Map<String, Object>();
		
		
		Test.startTest();
			
			installHandler.beforeInstall(context);
			
			installHandler.afterInstall(context);
			
			installHandler.beforeUpgrade(context);
			
			installHandler.afterUpgrade(context);
			
		Test.stopTest();
		
	}
	
	
}