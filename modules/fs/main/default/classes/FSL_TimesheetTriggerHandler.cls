/**=========================================================================================
@Description: Trigger Handler for all Timesheet record events.
=========================================================================================*/
public class FSL_TimesheetTriggerHandler extends TriggerHandler {
    
 public override void afterInsert(List<SObject> newList,Map<Id, SObject> newMap){
		FSL_TimesheetTriggerHandlerService.generateReport(newList);
    }
}