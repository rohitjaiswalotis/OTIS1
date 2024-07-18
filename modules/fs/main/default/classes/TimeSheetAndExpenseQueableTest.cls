/*
Developed by - Rupal Sharma 
Created date - 17/06/2024
LastModified By - Guru
LastModified On - 27/06/2024
Description: Test Class for TimeSheetAndExpenseQueable.
*/
@isTest
public class TimeSheetAndExpenseQueableTest {
    
    @testSetup
    static void setupData() {
        
        CS_TriggerSettings__c setting=UTIL_TestDataFactory.createTriggerSettings('TimeSheet');
        insert setting;
        
        CS_TriggerSettings__c setting2=UTIL_TestDataFactory.createTriggerSettings('ExpenseReport');
        insert setting2;
        
        //CusttomSetting Creation from Expense
        CS_TriggerSettings__c setting3=UTIL_TestDataFactory.createTriggerSettings('Expense');
        insert setting3;
          
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
        
        OTIS_Expense_Setting__c otisExpSet = FSL_TestDataFactory.createOtisExpenseSetting('Otis Sample Data','OTIS NAA',999.99,999.99,999.99,999.99,999.99);
        insert otisExpSet;
        
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
    //TestMethod to cover Expense Report Record Share with Service Resource Office Members
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
    //TestMethod to cover Expense Record Share with Service Resource Office Members
    @isTest
    static void expenseShareTest(){
        user manager =[SELECT Id FROM user WHERE username='userToUpdate@manager1.com'];
        ServiceResource serRes= [Select Id FROM ServiceResource WHERE Name='TestingResource'];
        
        List<Expense> listOfExp = FSL_TestDataFactory.createExpense(serRes.Id,Date.Today(),'Zone',10,1);
        Test.startTest();
        insert listOfExp;
        Test.stopTest();
        
        ExpenseShare[] expList = [SELECT Id FROM ExpenseShare where ParentId=:listOfExp[0].Id];
        System.assertEquals(True,expList!=Null);
    }
    @isTest
    static void testExecute() {

        user userRec=[select id , name from user where username='userToUpdate@test.com' ];
         user supervisor=[select id , name from user where username='userToUpdate@manager1.com' ];
         
        serviceResource ResourceId = [Select id,Name from serviceResource where Name='TestingResource'];
        
        List<TimeSheet> timeSheets = UTIL_TestDataFactory.createTimeSheet('New', ResourceId.id,Date.Today(),Date.Today(),userRec.Id,userRec.id,2);
        List<ExpenseReport> expenseReports = UTIL_TestDataFactory.createExpenseReportRec('New', ResourceId.Id,Date.Today(),Date.Today(),userRec.id,supervisor.id,2);
       
        list<ExpenseReport>  updateToExpenseRep = new List<ExpenseReport>();
        List<ExpenseReport> expenseReportsRec = UTIL_TestDataFactory.createExpenseReportRec('New', ResourceId.Id,Date.Today(),Date.Today(),userRec.id,userRec.id,1);
        insert expenseReportsRec;
        expenseReportsRec[0].Status__c = 'Approved';
        updateToExpenseRep.add(expenseReportsRec[0]);
        update updateToExpenseRep;
        
        delete updateToExpenseRep;
        
        Test.startTest();
         insert expenseReports;
          insert timeSheets;
        Test.stopTest();

    }
}