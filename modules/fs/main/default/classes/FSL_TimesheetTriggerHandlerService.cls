/*
Developed by - Cognizant
Created date - 6/10/2024
LastModified On - 09/07/2024
@Description:  *Ability to generate standard expense report for Service Resource per week on creation of TimeSheet 
* Create Time Sheet Share record for Supervisor and Branch manager
*/

public class FSL_TimesheetTriggerHandlerService {
    public static void generateReport(List<TimeSheet> timesheetData){
        try {
            List<ExpenseReport> expenseReportData = new List<ExpenseReport>();
            set<Id> setOfTimeSheetId = new Set<Id>(); 
            // Fetch ServiceResource data and map it by ID
            Map<Id, ServiceResource> resourceMap = new Map<Id, ServiceResource>([
                SELECT Id, Name, WDEmployeeID__c, RelatedRecordId, Branch__c 
                FROM ServiceResource
            ]);
            
            // Fetch User data and map it by ID to Manager ID
            Map<Id, Id> userToManagerMap = new Map<Id, Id>();
            for (User user : [SELECT Id, ManagerId FROM User WHERE ManagerId != NULL]) {
                userToManagerMap.put(user.Id, user.ManagerId);
            }
            
            // Fetch Branch data and map it by ID to Branch Manager ID
            Map<Id, Id> branchToManagerMap = new Map<Id, Id>();
            for (Branch__c branch : [SELECT Id, BranchManager__c FROM Branch__c WHERE BranchManager__c != NULL]) {
                branchToManagerMap.put(branch.Id, branch.BranchManager__c);
            }
            
            // Fetch InternalResource data and map it by ID to User ID
            Map<Id, Id> branchManagerToUserIdMap = new Map<Id, Id>();
            for (InternalResource__c resource : [SELECT Id, User__c FROM InternalResource__c WHERE User__c != NULL]) {
                branchManagerToUserIdMap.put(resource.Id, resource.User__c);
            }
            
            // Process each timesheet to create ExpenseReports
            for (TimeSheet ts : timesheetData) {
                setOfTimeSheetId.add(ts.Id);
                ExpenseReport report = new ExpenseReport();
                String title = 'ER';
                String managerId = null;
                String branchManager = null;
                
                if (resourceMap.containsKey(ts.ServiceResourceId)) {
                    ServiceResource resource = resourceMap.get(ts.ServiceResourceId);
                    report.Service_Resource__c = resource.Id;
                    title += resource.Name + ' ' + resource.WDEmployeeID__c;
                    
                    // Get the manager ID if exists
                    if (resource.RelatedRecordId != null && userToManagerMap.containsKey(resource.RelatedRecordId)) {
                        managerId = userToManagerMap.get(resource.RelatedRecordId);
                    }
                    
                    // Get the branch manager if exists
                    if (resource.Branch__c != null && branchToManagerMap.containsKey(resource.Branch__c)) {
                        Id branchManagerId = branchToManagerMap.get(resource.Branch__c);
                        if (branchManagerId != null && branchManagerToUserIdMap.containsKey(branchManagerId)) {
                            branchManager = branchManagerToUserIdMap.get(branchManagerId);
                        }
                    }
                }
                
                // Set the report data
                report.Title = (title + Date.valueOf(ts.EndDate)).replaceAll('null', '');
                report.Supervisor__c = managerId;
                report.Branch_Manager__c = branchManager;
                report.Status__c = UTIL_Constants.CASE_STATUS_NEW;
                report.StartDate__c = ts.StartDate;
                report.EndDate__c = ts.EndDate;
                
                expenseReportData.add(report);
            }            
            // Insert the expense reports
            Database.insert(expenseReportData);
            if(!setOfTimeSheetId.IsEmpty() && setOfTimeSheetId!=Null){
                createTimeSheetShare(setOfTimeSheetId);
            }
        } catch (Exception ex) {
            Logger.logException(ex);
        }
    }
    /**
* Create the Time Sheet share record for the supervisora and the branch manager
*
* @param newList List of SObject records to process.
*/
    @future
    public static void createTimeSheetShare(Set<Id> timesheetIds){
        try{
            set<id> OfficeIds = new set<id>();
            set<id> resourceIds = new set<id>();
            map<id,serviceResource> resourceIdVSdata = new  map<id,serviceResource>();
            List<TimeSheetshare> ListToAddSharing = new List<TimeSheetShare>();
            List<TimeSheet> timeSheets = new list<TimeSheet>();
            
            timeSheets =[select id ,ServiceResourceId,BranchManager__c, Supervisor__c
                         from TimeSheet where id in:timesheetIds ];
            
            if(!timeSheets.IsEmpty() && timeSheets!=Null){
                
                for (TimeSheet timeSheeObj : timeSheets) {
                    //get serviceResourceIds 
                    resourceIds.add(timeSheeObj.ServiceResourceId);
                }
                
                //get OfficeIds from service resource  if timesheet is created for helper
                for(serviceResource resource :[select id , name ,FS_IsHelper__c, JobTitle__c, Branch__c from serviceResource
                                               where (FS_IsHelper__c=true OR JobTitle__c='Helper')
                                               AND  Branch__c!=null 
                                               AND id in:resourceIds])
                {
                    OfficeIds.add(resource.Branch__c); 
                    resourceIdVSdata.put(resource.id,resource);
                }
                
                //get all mechanics related to the same branch of Helper  
                map<id,set<id>> branchVSresouceIds = new  map<id,set<id>>();
                for(BranchMemberRole__c officeMembers: [SELECT Id,Branch__c,InternalResource__r.User__c,
                                                        BookableResource__r.RelatedRecordId FROM BranchMemberRole__c 
                                                        WHERE Branch__c In: OfficeIds])
                {
                    set<id> temp = new set<id>(); 
                    if(branchVSresouceIds.containskey(officeMembers.Branch__c)) {
                        temp=branchVSresouceIds.get(officeMembers.Branch__c);
                        temp.add(officeMembers.BookableResource__r.RelatedRecordId);
                        branchVSresouceIds.put(officeMembers.Branch__c,temp);  
                    }
                    else{
                        temp.add(officeMembers.BookableResource__r.RelatedRecordId);
                        branchVSresouceIds.put(officeMembers.Branch__c,temp);    
                    }                                      
                }
                
                
                for (TimeSheet timeSheeObj : timeSheets) {
                    //share record with Branch manager
                    if (timeSheeObj.BranchManager__c != null) {
                        TimeSheetShare  TimeSheObj = createRecordOfTimeSheetShare(timeSheeObj.id,timeSheeObj.BranchManager__c);
                        ListToAddSharing.add(TimeSheObj);
                    }
                    //share record with Supervisor 
                    if (timeSheeObj.Supervisor__c != null) {
                        TimeSheetShare  TimeSheObj1 = createRecordOfTimeSheetShare(timeSheeObj.id,timeSheeObj.Supervisor__c);
                        ListToAddSharing.add(TimeSheObj1);
                    }
                    
                    //share record with Mechanic if timesheet is created for Helper 
                    if (timeSheeObj.ServiceResourceId != null && 
                        resourceIdVSdata.containskey(timeSheeObj.ServiceResourceId) && 
                        resourceIdVSdata.get(timeSheeObj.ServiceResourceId).branch__c!=null && 
                        branchVSresouceIds.containskey(resourceIdVSdata.get(timeSheeObj.ServiceResourceId).branch__c) &&
                        branchVSresouceIds.get(resourceIdVSdata.get(timeSheeObj.ServiceResourceId).branch__c)!=null
                       ) { 
                           
                           list<TimeSheetShare>  TimeSheObj1 = createRecordOfExpenseRepShareBranchMem(timeSheeObj.id,
                                                                                                branchVSresouceIds.get(resourceIdVSdata.get(timeSheeObj.ServiceResourceId).branch__c));
                           ListToAddSharing.addall(TimeSheObj1);
                       }
                }
                if (!ListToAddSharing.isEmpty()) {
                    database.insert(ListToAddSharing,false);
                }
            }
        }
        catch(exception ex){
            Logger.logException(ex);
        }
    }
    
    // This Method is used to return Permission Record for give Access to SuperVisoor and manager on TimeSheet.
    private  Static  TimeSheetShare createRecordOfTimeSheetShare(string timeSheetid, string userid){
        TimeSheetShare shareRecObj = new TimeSheetshare();
        shareRecObj.ParentId = timeSheetid;
        shareRecObj.UserOrGroupId =userid;
        shareRecObj.AccessLevel = 'Edit';
        shareRecObj.RowCause = Schema.TimeSheetShare.RowCause.Manual;
        return shareRecObj;
    }
    //This Method is used to create Record share Access to Office Members from expense report's Service Resource Office
    private  Static List<TimeSheetShare> createRecordOfExpenseRepShareBranchMem(string expenseId , Set<Id> setOfUserId){
        List<TimeSheetShare> listOfTimesheetShare = new List<TimeSheetShare>();
        if(!setOfUserId.ISEmpty() && setOfUserId != Null){
            for(Id userId: setOfUserId){
                TimeSheetShare ShareRecObj = new TimeSheetShare();
                ShareRecObj.ParentId = expenseId;
                ShareRecObj.UserOrGroupId = userId;
                ShareRecObj.AccessLevel = 'Edit';
                ShareRecObj.RowCause = Schema.TimeSheetShare.RowCause.Manual;
                listOfTimesheetShare.add(ShareRecObj);
            }
        }
        return listOfTimesheetShare;
    }
    
}