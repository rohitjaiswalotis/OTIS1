/*=======================================================================================================
Developed by - Guru 
Created date - 03/07/2024
Description: #1035155 - The batch shorten the time sheet/expense report for future week by adjusting the end date in case of holiday based on flow Inputs, 
Logs the entry records created on adjusted dates to future week Expense Report and Timesheet Record.
=======================================================================================================*/
public class TimesheetModificationDataBatch implements Database.batchable<sObject>,Database.Stateful{ 
     /*
      * @description: Wrapperclass used to store inputs from Flow
      * */     
    public class adjustmentHolidayDates{
        @invocableVariable public Datetime scheduleTime;
        @invocableVariable public Boolean isScheduleRun;
        @invocableVariable public String batch;
    }
    /*
     * @description: start method for Batch Apex
     * @param: bc - Batchable context
     * @return: Database.QueryLocator
     */ 
    public Database.QueryLocator start(Database.BatchableContext BC){
        String queryString = 'SELECT Id,Adjusted_Start_Date__c,Adjusted_End_Date__c,Original_Start_Date__c,Original_End_Date__c,Processed__c'
            				 +' FROM Holiday_Adjustment__c WHERE Processed__c = FALSE ORDER BY Original_Start_Date__c ASC LIMIT 1';
        return Database.getQueryLocator(queryString);
    }    
    /*
     * @description: execute method for Batch Apex
     * @param: bc - Batchable context
     * @param: Holiday Adjustment - List of Holiday Adjustment records
     */ 
    public void execute(Database.BatchableContext info, List<Holiday_Adjustment__c> scope){
        List<TimeSheet> listOfTimeSheet= new List<TimeSheet>();
        List<ExpenseReport> listOfExpenseReport = new List<ExpenseReport>();
        List<TimeSheet> listOfNewTimeSheet= new List<TimeSheet>();
        List<ExpenseReport> listOfNewExpenseReport = new List<ExpenseReport>();
        List<TimeSheetEntry> listOfTimeSheetEntry = new List<TimeSheetEntry>();
        List<TimeSheetEntry> listOfCopyTimeSheetEntry = new List<TimeSheetEntry>();
        List<ExpenseReportEntry> listOfExpenseRepEntry = new List<ExpenseReportEntry>();
        List<ExpenseReportEntry> listOfCopyExpenseRepEntry = new List<ExpenseReportEntry>();
        Map<Id,Id> mapOfSrIdVsTsId = new Map<Id,Id>();
        Map<Id,Id> mapOfSridVsErId = new Map<Id,Id>();
        Set<Id> setOfSRTimeSheet = new Set<Id>();
        Set<Id> setOfTsId = new Set<Id>();
        Set<Id> setOfErId = new Set<Id>();
        Integer totalDaysOfHolidayAdjustment = 0;
        try{
            if(!scope.IsEmpty() && scope!=NUll){
                //Adjust the TimeSheet/Expense Report End Date and Create short week TimeSheet Record
                if(scope[0].Original_Start_Date__c == scope[0].Adjusted_Start_Date__c){
                        listOfTimeSheet = [SELECT Id,StartDate,EndDate,Status,ServiceResourceId FROM TimeSheet WHERE StartDate =: scope[0].Original_Start_Date__c AND EndDate=: scope[0].Original_End_Date__c];
                        listOfExpenseReport = [SELECT Id,StartDate__c,EndDate__c,Status__c,Service_Resource__c FROM ExpenseReport WHERE StartDate__c =:scope[0].Original_Start_Date__c AND EndDate__c =:scope[0].Original_End_Date__c];
                        
                        totalDaysOfHolidayAdjustment = scope[0].Adjusted_End_Date__c.daysBetween(scope[0].Original_End_Date__c);
                        if(!listOfTimeSheet.IsEmpty() && listOfTimeSheet!=Null){
                            for(TimeSheet ts:listOfTimeSheet){
                                ts.EndDate = scope[0].Adjusted_End_Date__c;
                                setOfSRTimeSheet.add(ts.ServiceResourceId);
                            }
                            Database.update(listOfTimeSheet,false);
                        }
                        if(!listOfExpenseReport.IsEmpty() && listOfExpenseReport!=Null){
                            for(ExpenseReport er:listOfExpenseReport){
                                er.EndDate__c = scope[0].Adjusted_End_Date__c;
                            }
                            Database.update(listOfExpenseReport,false);
                        }  
                        if(!setOfSRTimeSheet.IsEmpty() && setOfSRTimeSheet!=Null){
                            for(Id srId:setOfSRTimeSheet){
                                TimeSheet ts = new TimeSheet();
                                ts.StartDate = scope[0].Adjusted_End_Date__c.addDays(1);
                                ts.EndDate = scope[0].Adjusted_End_Date__c.addDays(totalDaysOfHolidayAdjustment);
                                ts.Status = 'New';
                                ts.ServiceResourceId = srId;
                                listOfNewTimeSheet.add(ts);
                            }
                            if(!listOfNewTimeSheet.IsEmpty() && listOfNewTimeSheet!=Null){
                                Database.Insert(listOfNewTimeSheet,false);
                            }
                        }
                
                    scope[0].Processed__c = True;
                    Database.Update(scope,false);
                }
                else if(scope[0].Adjusted_Start_Date__c < scope[0].Original_Start_Date__c){
                    
                    totalDaysOfHolidayAdjustment = scope[0].Adjusted_Start_Date__c.daysBetween(scope[0].Original_Start_Date__c)-1;
                    //Query short week Time sheet/Expense Reports
                    listOfTimeSheet = [SELECT Id,StartDate,EndDate,Status,ServiceResourceId 
                                       FROM TimeSheet 
                                       WHERE StartDate =: scope[0].Adjusted_Start_Date__c AND EndDate=: scope[0].Adjusted_Start_Date__c.addDays(totalDaysOfHolidayAdjustment)];
                    listOfExpenseReport = [SELECT Id,StartDate__c,EndDate__c,Status__c,Service_Resource__c 
                                           FROM ExpenseReport 
                                           WHERE StartDate__c =:scope[0].Adjusted_Start_Date__c AND EndDate__c =:scope[0].Adjusted_Start_Date__c.addDays(totalDaysOfHolidayAdjustment)];
                    
                    if(!listOfTimeSheet.IsEmpty() && listOfTimeSheet!=Null){
                        for(TimeSheet ts:listOfTimeSheet){
                            setOfTsId.add(ts.Id);
                        }
                    }
                    
                    if(!listOfExpenseReport.IsEmpty() && listOfExpenseReport!=Null){
                        for(ExpenseReport er:listOfExpenseReport){
                            setOfErId.add(er.Id);
                        }
                    }
                    
                    //Query future week Time shhet/Expense Report
                    listOfNewTimeSheet = [SELECT Id,StartDate,EndDate,Status,ServiceResourceId 
                                          FROM TimeSheet 
                                          WHERE StartDate =: scope[0].Original_Start_Date__c AND EndDate=: scope[0].Original_End_Date__c];
                    
                    listOfNewExpenseReport = [SELECT Id,StartDate__c,EndDate__c,Status__c,Service_Resource__c 
                                              FROM ExpenseReport 
                                              WHERE StartDate__c =:scope[0].Original_Start_Date__c AND EndDate__c =:scope[0].Original_End_Date__c];
                                   
                    if(!listOfNewTimeSheet.IsEmpty() && listOfNewTimeSheet!=Null){
                        for(TimeSheet ts:listOfNewTimeSheet){
                            ts.StartDate = scope[0].Adjusted_Start_Date__c;
                            if(!mapOfSrIdVsTsId.containsKey(ts.ServiceResourceId)){
                                mapOfSrIdVsTsId.put(ts.ServiceResourceId,ts.Id);
                            }
                        }
                        Database.update(listOfNewTimeSheet,false);
                    }
                    
                    if(!listOfNewExpenseReport.IsEmpty() && listOfNewExpenseReport!=Null){
                        for(ExpenseReport er:listOfNewExpenseReport){
                            er.StartDate__c = scope[0].Adjusted_Start_Date__c;
                            if(!mapOfSridVsErId.containsKey(er.Service_Resource__c)){
                                mapOfSridVsErId.put(er.Service_Resource__c,er.Id);
                            }
                        }
                        Database.update(listOfNewExpenseReport,false);
                    }
                    
                    if(!setOfTsId.IsEmpty() && setOfTsId!=Null){
                        listOfTimeSheetEntry = [SELECT Id,TimeSheet.ServiceResourceId,StartTime,EndTime,PayCode__c,Status,Type,Multiplier_Type__c,Multiplier_Values__c,WorkOrderLineItemId,LocationTimeZone,WorkOrderId,Subject
                                                FROM TimeSheetEntry WHERE TimeSheetId In: setOfTsId];
                        
                        if(!listOfTimeSheetEntry.IsEmpty() && listOfTimeSheetEntry!=Null){
                            for(TimeSheetEntry tse:listOfTimeSheetEntry){
                                TimeSheetEntry nTse = new TimeSheetEntry();
                                nTse.StartTime = tse.StartTime;
                                nTse.EndTime = tse.EndTime;
                                nTse.PayCode__c = tse.PayCode__c;
                                nTse.Status =tse.Status;
                                nTse.Type = tse.Type;
                                nTse.Subject = tse.Subject;
                                nTse.Multiplier_Type__c =tse.Multiplier_Type__c;
                                nTse.Multiplier_Values__c = tse.Multiplier_Values__c;
                                nTse.WorkOrderLineItemId =tse.WorkOrderLineItemId;
                                nTse.LocationTimeZone = tse.LocationTimeZone;
                                nTse.WorkOrderId = tse.WorkOrderId;
                                nTse.TimeSheetId = mapOfSrIdVsTsId.get(tse.TimeSheet.ServiceResourceId);
                                listOfCopyTimeSheetEntry.add(nTse);
                            }
                            
                            if(!listOfCopyTimeSheetEntry.IsEmpty() && listOfCopyTimeSheetEntry!=Null){
                                Database.insert(listOfCopyTimeSheetEntry,false);
                            }                            
                        }
                        Database.delete(listOfTimeSheet,false);
                    }
                    
                    if(!setOfErId.IsEmpty() && setOfErId!=Null){
                        listOfExpenseRepEntry = [SELECT Id,ExpenseId,ExpenseReportId,ExpenseReport.Service_Resource__c FROM ExpenseReportEntry WHERE ExpenseReportId In: setOfErId];
                        
                        if(!listOfExpenseRepEntry.IsEmpty() && listOfExpenseRepEntry!=Null){
                            for(ExpenseReportEntry er:listOfExpenseRepEntry){
                                ExpenseReportEntry ere = new ExpenseReportEntry();
                                ere.ExpenseId = er.ExpenseId;
                                ere.ExpenseReportId = mapOfSridVsErId.get(er.ExpenseReport.Service_Resource__c);
                                listOfCopyExpenseRepEntry.add(ere);
                            }
                            
                            if(!listOfCopyExpenseRepEntry.ISEmpty() && listOfCopyExpenseRepEntry!=Null){
                                Database.Insert(listOfCopyExpenseRepEntry,false);
                            }
                        }
                        Database.delete(listOfExpenseReport,false);
                    }
                    scope[0].Processed__c = True;
                    Database.Update(scope,false);
                    
                }
            }
        } Catch(Exception e){
             Logger.logException(e);
        }
    }
    /*
     * @description: finish method for Batch Apex
     * @param: bc - Batchable context
     */ 
    public void finish(Database.BatchableContext info){    
        if(!Test.isRunningTest()){
            String batchName = 'ScheduleJob for TimesheetModificationDataBatch on'+String.ValueOf(Date.Today());
            CronTrigger jobRecord = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: batchName];
            System.abortJob(jobRecord.Id);
        }
    }
    /*
     * @description: This method takes inputs from Flow and executes this Batch class
     * @param: requests - List of adjustmentHolidayDates
     */ 
    @InvocableMethod(Label='GetAdjustmentHolidayDates')
    public static void getShiftResult(List<adjustmentHolidayDates> requests){
        if(!requests.isEmpty() && requests[0]?.isScheduleRun != null && requests[0]?.isScheduleRun && requests[0]?.scheduleTime != null){
            String cronExp = generateCronExpression(requests[0]?.scheduleTime);
            System.schedule('ScheduleJob for TimesheetModificationDataBatch on'+requests[0].batch,cronExp,new TimesheetModificationData());
        }
    }
	/*
     * @description: Generates a cron expression from a Datetime object
     * @param: schedDateTime - Datetime object for scheduling
     * @return: String - cron expression
     */     
    private static String generateCronExpression(Datetime schedDateTime){
        return String.Valueof(schedDateTime.second()+' '+schedDateTime.minute()+' '+schedDateTime.hour()+' '+schedDateTime.day()+' '+schedDateTime.month()+' ? '+schedDateTime.year());
    }
}