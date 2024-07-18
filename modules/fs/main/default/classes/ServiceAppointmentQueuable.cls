/*
Developed by - Cognizant
Created date - 7/03/2024
LastModified By - Rupal
##1033393 This Queueable is used to update Service appointment and is used to create Time sheet entry Records on Conpleted Appointments
*/
 
 
public class ServiceAppointmentQueuable implements Queueable{ 
    private list<serviceAppointment> saList;
    private Map<Id,ServiceAppointment> oldMap;
     // Constructor
    public ServiceAppointmentQueuable(List<serviceAppointment> saList ,Map<Id,ServiceAppointment> oldMap) {
        this.saList = saList;
        this.oldMap = oldMap;
    }
    // This method will be called when the job is executed
    public void execute(QueueableContext context) {
               insertTimesheetEntryRecords(saList,oldMap);
    }
    public static void insertTimesheetEntryRecords(list<serviceAppointment> saList,Map<Id,ServiceAppointment> oldMap){
        try{
             map<id,id> workorderVSresource = new  map<id,id>();
            set<date> travelTime = new  set<date>();
            for(ServiceAppointment SA :saList){
                if((SA.status=='Completed'|| SA.status=='Cannot Complete') && SA.status!=oldMap.get(SA.id).status){
                    travelTime.add(date.valueof(SA.CompletionTimeStamp__c) );
                    travelTime.add(date.valueof(SA.Incomplete_Date_Time__c) );
                    workorderVSresource.put(SA.ParentRecordId,SA.AssignedServiceResource__c);
                }
            }
             map<id,id> resourceVStimesheet=getTimesheetForCompletedAppointment(travelTime,workorderVSresource.values());
            list<TimeSheetEntry> tseList = new  list<TimeSheetEntry>();
            for(ServiceAppointment SA :saList){
                    string timesheetId;
                    if(workorderVSresource.containskey(sa.parentrecordid)){
                      timesheetId= resourceVStimesheet.get(workorderVSresource.get(sa.parentrecordid));
                    } 
                    if(timesheetId!=null && timesheetId!=''){
                        dateTime workCompleteDate=SA.CompletionTimeStamp__c!=null?SA.CompletionTimeStamp__c:SA.Incomplete_Date_Time__c;
                        if((SA.status=='Completed' || SA.status=='Cannot Complete') && SA.status!=oldMap.get(sa.id).status){
                      tseList.add(createTimesheetEntry(SA.TravelTimeStamp__c,timesheetId,SA.OnSiteTimeStamp__c,
                                             'Travel','Regular',
                                             SA.AssignedServiceResource__r.TimeZone__c,SA.ParentRecordId,
                                             SA.Estimated_Travel_Time__c));
                       tseList.add(createTimesheetEntry(SA.OnSiteTimeStamp__c,timesheetId,workCompleteDate,
                                             'Work','Regular',
                                             SA.AssignedServiceResource__r.TimeZone__c,SA.ParentRecordId,
                                             null));  
                    }
                    }

            }
            Insert tseList;
        }
        catch(exception ex){
            Logger.logException(ex); 
        }
    }
    private static map<id,id> getTimesheetForCompletedAppointment(set<date> travelTime,list<id> resourceIds){
       map<id,id> resourceVStimesheet = new  map<id,id>();
       for(TimeSheet ts:[select id,ServiceResourceId,StartDate,enddate from TimeSheet 
                        where ServiceResourceId in:resourceIds])
       {
           for(date dts :travelTime){
               if(dts>=ts.startdate && dts<=ts.endDate){ 
                 resourceVStimesheet.put(ts.ServiceResourceId,ts.id);   
               }
               }
       }
        return resourceVStimesheet;
   }
    public static TimeSheetEntry createTimesheetEntry(dateTime StartTime,string TimeSheetId,dateTime EndTime,
                                                       string TypeVal, string MultiplierType
                                            ,string LocationTimeZone,Id WorkOrderId,decimal EstimatedTravelTime){
                    TimeSheetEntry tse = new TimeSheetEntry();
                    tse.StartTime=StartTime;
                    tse.TimeSheetId=timesheetId; //timesheet related to assigned resource of appointment woVStimesheet ,resourceVStimesheet
                    tse.EndTime=EndTime;
                    tse.Type=TypeVal;
                    tse.Multiplier_Type__c=MultiplierType;
                    tse.Multiplier_Values__c=1;
                    tse.LocationTimeZone=LocationTimeZone;
                    tse.WorkOrderId=WorkOrderId; 
                    tse.Estimated_Travel_Time__C =EstimatedTravelTime;   
        return tse;
    }
}