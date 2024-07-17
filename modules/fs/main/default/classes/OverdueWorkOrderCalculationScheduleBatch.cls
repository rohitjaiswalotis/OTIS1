/**=========================================================================================
Created by - Jaya Prasanth
Created date - 05/07/2024
Description - Scheduling the Batch class.
=========================================================================================*/
global with sharing class OverdueWorkOrderCalculationScheduleBatch implements Schedulable {
		 global void execute(SchedulableContext sc){
         OverdueWorkOrderCalculationBatch b=new OverdueWorkOrderCalculationBatch();
         Database.executeBatch(b, 2000);
    }
}