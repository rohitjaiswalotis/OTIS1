/*
Developed by - Cognizant
Created date - 6/10/2024
LastModified On - 09/07/2024
@Description:  Test Class for TimeSheetTrigger, TimesheetTriggerHandler, and FSL_TimesheetTriggerHandlerService Class
*/
@IsTest(SeeAllData=false)
public with sharing class FSL_TimesheetTriggerHandlerServiceTest {
@testSetup
    static void setup() {
        
        CS_TriggerSettings__c setting=UTIL_TestDataFactory.createTriggerSettings('TimeSheet');
        insert setting;
        system.debug(setting);
        
        User manager = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.otis.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','userToUpdate@manager1.com','');
        insert manager;
        
        user mechanics = UTIL_TestDataFactory.createUserRec('u2u','userToUpdate@test.otis.com','UTF-8','ToUpdate','en_US','en_US','Standard User', 'America/Los_Angeles','userToUpdate@test.com', manager.Id);
        insert mechanics;
        
       
        
        InternalResource__c branchManager =UTIL_TestDataFactory.createInternalResource('testManager', null,'123567', 'branch manager', 'test@cognizant.com');
        branchManager.user__c=manager.id;
        insert branchManager; 
        
         
        Branch__c officeRec = UTIL_TestDataFactory.createBranch('Dev Hub', 'Branch', null); 
        officeRec.BranchManager__c=branchManager.id;
        insert officeRec;
        
        ServiceResource serviceResource = UTIL_TestDataFactory.createServiceResource('TestingResource' ,mechanics.Id ,'1234567890','test@gmail.com');
        serviceResource.Branch__c=officeRec.id;
        insert serviceResource;
        
    }
    
    @isTest
    static void testTimeSheetShare(){
        User userRec=[select id , name from user where username='userToUpdate@test.com'];
        User supervisor=[select id , name from user where username='userToUpdate@manager1.com'];
        serviceResource ResourceId = [Select id,Name from serviceResource where Name='TestingResource'];
        List<TimeSheet> timeSheets = UTIL_TestDataFactory.createTimeSheet('New', ResourceId.id,Date.Today(),Date.Today(),userRec.Id,userRec.id,2);
        Test.startTest();
        insert timeSheets;
        Test.stopTest();
    }
    
}