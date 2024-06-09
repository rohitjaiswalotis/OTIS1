/**
* Test class for Core package install handler.
*/
@IsTest
public inherited sharing class FS_CoreInstallHandlerImplTest {
	
	
	@isTest
	static void basic() {
		
		CoreInstallHandler installHandler = new FS_CoreInstallHandlerImpl();
		
		Map<String, Object> context = new Map<String, Object>();
		
		
		Test.startTest();
			
			installHandler.beforeInstall(context);
			
			installHandler.afterInstall(context);
			
			installHandler.beforeUpgrade(context);
			
			installHandler.afterUpgrade(context);
			
		Test.stopTest();
		
	}
	
}