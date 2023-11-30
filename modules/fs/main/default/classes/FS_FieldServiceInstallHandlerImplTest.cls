/**
* Test class for interface to implementation resolver. 
*/
@IsTest
public inherited sharing class FS_FieldServiceInstallHandlerImplTest {
	
	
	@isTest
	static void basic() {
		
		FS_FieldServiceInstallHandler installHandler = new FS_FieldServiceInstallHandlerTestImpl();
		
		Map<String, Object> context = new Map<String, Object>();
		
		
		Test.startTest();
			
			installHandler.beforeInstall(context);
			
			installHandler.afterInstall(context);
			
			installHandler.beforeUpgrade(context);
			
			installHandler.afterUpgrade(context);
			
		Test.stopTest();
		
	}
	
	
	public class FS_FieldServiceInstallHandlerTestImpl implements FS_FieldServiceInstallHandler {
		
		
		public void beforeInstall(Map<String, Object> context) {
			
		}
		
		
		public void afterInstall(Map<String, Object> context) {
			
		}
		
		
		public void beforeUpgrade(Map<String, Object> context) {
			
		}
		
		
		public void afterUpgrade(Map<String, Object> context) {
			
		}
		
		
	}
	
	
}