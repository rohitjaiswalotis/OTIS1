/**=========================================================================================
Developed by - Guru
Created date - 04/07/2024
Description - Test class for TimesheetModificationDataBatch and TimesheetModificationData class.
=========================================================================================*/

@IsTest(SeeAllData=false)
public with sharing class TimesheetModificationDataBatchTest {
    @testSetup
    static void setup() {
        
        CS_TriggerSettings__c setting=UTIL_TestDataFactory.createTriggerSettings('TimeSheet');
        insert setting;
        
        OTIS_Expense_Setting__c otisExpSet = FSL_TestDataFactory.createOtisExpenseSetting('Otis Sample Data','OTIS NAA',999.99,999.99,999.99,999.99,999.99);
        insert otisExpSet;
        
        String PhoneNumber = '0000-0000-00';
        String EmailId = 'testing@gmail.com';
        
        List<User> mechanics = UTIL_TestDataFactory.createUsers(UTIL_Constants.FIELD_SERVICE_MECHANIC_PROFILE,1);
        insert mechanics;
        
        ServiceResource serviceResource = UTIL_TestDataFactory.createServiceResource('TestingResource' ,mechanics[0].Id ,PhoneNumber,EmailId);
        serviceResource.Company__c='OTIS NAA';
        insert serviceResource;
        
        List<TimeSheet> timeSheet1 = UTIL_TestDataFactory.createTimeSheet('New' , serviceResource.ID , Date.today().addDays(6), Date.today(), 1);
        insert timeSheet1;
        
        List<TimeSheet> timeSheet2 = UTIL_TestDataFactory.createTimeSheet('New' , serviceResource.ID, Date.Today().addDays(13),Date.Today().addDays(7),1);
        insert timeSheet2;
        
        List<Expense> listOfExp = FSL_TestDataFactory.createExpense(serviceResource.Id,Date.Today(),'Zone',10.00,1);
        insert listOfExp;
    }
    
    @isTest
    static void testCurrentWeekTsEr(){
		Holiday_Adjustment__c aHol1 = FSL_TestDataFactory.createHolidayAdjustment(Date.Today(),Date.Today().addDays(6),Date.Today(),Date.Today().addDays(4),false);
        insert aHol1;
        Test.startTest();
        TimesheetModificationDataBatch batch = new TimesheetModificationDataBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        Holiday_Adjustment__c holidayAdjust = [SELECT Id,Processed__c 
                                               FROM Holiday_Adjustment__c WHERE Processed__c = TRUE LIMIT 1];
        Assert.isTrue(holidayAdjust.Processed__c);
    }
    
    @isTest
    static void testNextWeekTsEr(){
        Holiday_Adjustment__c aHol2 = FSL_TestDataFactory.createHolidayAdjustment(Date.Today().addDays(7),Date.Today().addDays(13),Date.Today().addDays(5),Null,false);
        insert aHol2;
        ServiceResource serviceResource = [Select Id from ServiceResource Limit 1];
        Expense exp = [SELECT Id FROM Expense WHERE ServiceResource__c =:serviceResource.Id LIMIT 1];
        List<TimeSheet> timeSheet = UTIL_TestDataFactory.createTimeSheet('New' , serviceResource.Id, Date.today().addDays(6), Date.today().addDays(5), 1);
        insert timeSheet;
        
        List<TimeSheetEntry> timeSheetEntry = UTIL_TestDataFactory.createTimeSheetEntry('New', timeSheet[0].Id, Date.Today().addDays(6), Date.Today().addDays(6), 1);
        insert timeSheetEntry;
        
        ExpenseReport expenseReport = [SELECT Id FROM ExpenseReport WHERE StartDate__c=:Date.today().addDays(5) LIMIT 1];
        
        ExpenseReportEntry expReportEntry = FSL_TestDataFactory.createExpenseReportEntry(exp.Id,expenseReport.Id);
        insert expReportEntry;
        
        Test.startTest();
        TimesheetModificationDataBatch batch = new TimesheetModificationDataBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        Holiday_Adjustment__c holidayAdjust = [SELECT Id,Processed__c 
                                               FROM Holiday_Adjustment__c WHERE Processed__c = TRUE LIMIT 1];
        Assert.isTrue(holidayAdjust.Processed__c);
    }
    
    @isTest
    static void testSchdeuleBatch(){
        Holiday_Adjustment__c aHol1 = FSL_TestDataFactory.createHolidayAdjustment(Date.Today(),Date.Today().addDays(6),Date.Today(),Date.Today().addDays(4),false);
        insert aHol1;
        TimesheetModificationDataBatch.adjustmentHolidayDates flowInput = new TimesheetModificationDataBatch.adjustmentHolidayDates();
        flowInput.batch = 'ScheduleJob for TimesheetModificationDataBatch on'+Date.Today().addDays(4);
        flowInput.isScheduleRun = True;
        flowInput.scheduleTime = Date.Today().addDays(4);
        List<TimesheetModificationDataBatch.adjustmentHolidayDates> flowInputsList = new List<TimesheetModificationDataBatch.adjustmentHolidayDates>{flowInput};
        Test.startTest();
        TimesheetModificationDataBatch.getShiftResult(flowInputsList);
        Test.stopTest();
    }
}