/*=======================================================================================================
Developed by - Cognizant
Created date - 09/07/2024
Description: Test class for FSL_ExpenseReportTrigger, FSL_ExpenseReportTriggerHandler, And FSL_ExpenseReportTriggerHandlerService.
==========================================================================================================*/
@IsTest(SeeAllData=false)
public class FSL_ExpenseReportHandlerServiceTest {
	
    @testSetup
    static void setupData(){
        CS_TriggerSettings__c setting2=UTIL_TestDataFactory.createTriggerSettings('ExpenseReport');
        insert setting2;
        
        User manager = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','userToUpdate@manager1.com','');
        insert manager;
        
        user mechanics = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','userToUpdate@test.com', manager.Id);
        insert mechanics;
        
        user mechanic2 = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','user1ToUpdate@test.com', manager.Id);
        insert mechanic2;
        
        user mechanic3 = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','user2ToUpdate@test.com', manager.Id);
        insert mechanic3;
        
		Branch__c office = UTIL_TestDataFactory.createBranch('Offiece','CDH','Branch',Null,'1 DEV HUB Way','Farmington','CT',Null,Null);
        insert office;
       
        ServiceResource serviceResource = UTIL_TestDataFactory.createServiceResource('TestingResource' ,mechanics.Id ,'1234567890','test@gmail.com');
        serviceResource.JobTitle__c ='Helper';
        serviceResource.Branch__c=office.Id;
        serviceResource.Company__c='OTIS NAA';
        insert serviceResource;   
        
        InternalResource__c internalResource = UTIL_TestDataFactory.createInternalResource('mechanic2',office.Id,Null,'Service Mechanic','test@gmail.com');
        internalResource.User__c= mechanic2.Id;
        insert internalResource;
		
        InternalResource__c internalResource1 = UTIL_TestDataFactory.createInternalResource('mechanic3',office.Id,Null,'Service Mechanic','test1@gmail.com');
        internalResource1.User__c= mechanic3.Id;
        insert internalResource1;
        
        BranchMemberRole__c officeMember1 = UTIL_TestDataFactory.createOfficeMember(office.id,internalResource.id,Null);
        insert officeMember1;
        
        BranchMemberRole__c officeMember = UTIL_TestDataFactory.createOfficeMember(office.id,internalResource1.id,Null);
        insert officeMember;
        
        BranchMemberRole__c officeMember2 = UTIL_TestDataFactory.createOfficeMember(office.id,Null,serviceResource.Id);
        insert officeMember2;
    }
    
    @isTest
    static void expenseReportShareTest(){
        user manager =[SELECT Id FROM user WHERE username='userToUpdate@manager1.com'];
        ServiceResource serRes= [Select Id FROM ServiceResource WHERE Name='TestingResource'];
        
        List<ExpenseReport> listOfExpenseReport = UTIL_TestDataFactory.createExpenseReportRec('New',serRes.Id,Date.Today(),Date.Today(),manager.Id,manager.Id,1);
        Test.startTest();
        insert listOfExpenseReport;
        Test.stopTest();
        
        ExpenseReportShare[] expRep = [Select Id,UserOrGroup.Name From ExpenseReportShare where ParentId =: listOfExpenseReport[0].Id];
        System.assertEquals(True,expRep!=Null);
    }
}