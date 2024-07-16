/*
Developed by -Cognizant 
Created date - 5/16/2024
#999711 get Modified Dates from flow for Timesheet Entries Adjustment 
*/
global with sharing class TimesheetModificationData implements Schedulable{
	global void execute(SchedulableContext sc){
        TimesheetModificationDataBatch batch=new TimesheetModificationDataBatch();
        Database.executeBatch(batch);
    }
}