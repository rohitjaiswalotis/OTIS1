/*=======================================================================================================
Developed by - Agnibha
Created date - 03/07/2024
LastModified By - Agnibha
LastModified On - 03/07/2024
Description -  Implement Apex Batch class for scheduled Route Reassignments.
==========================================================================================================*/
public class ScheduledRouteReassignmentJob implements schedulable,Database.Batchable<sObject>, Database.stateful{
    
    public void execute(SchedulableContext SC) {
        database.executebatch(new ScheduledRouteReassignmentJob(),20);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String soql ='select id,Route__c,RouteName__c,NextRoute__r.ServiceTerritory__c,FS_Effective_Date__c, NextRoute__c  from Asset where Branch__r.FSLEnabled__c =true and NextRoute__c  !=null';
        String query = !Test.isRunningTest() ? soql+' and FS_Effective_Date__c = TODAY' : soql ;
        return Database.getQueryLocator(query);
    }
    public void execute (Database.BatchableContext bc,List<Asset> assetRecList){
        try{
            FSLRouteReassignmentHandlerQueueable.handleRouteReassignmentOperation(assetRecList,New Map<Id,Asset>(assetRecList),null);
        }
        catch(Exception ex){
            Logger.logException(ex);
        }        
    }
    public void finish(Database.BatchableContext bc){}
}