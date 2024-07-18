/*=======================================================================================================
Developed by - Cognizant
Created date - 08/07/2024
Description: This class is used to aggregate Amount value on TotalExpenses__c field on WO.
==========================================================================================================*/
public inherited sharing class FSL_ExpenseHandlerService {
    
    // List of allowed Work Order Record Types
    public static final List<String> ALLOWED_WO_RECORD_TYPES = new List<String>{
        FSLConstantClass.WORK_ORDER_SERVICE_REQUEST_RT, 
        FSLConstantClass.WORK_ORDER_MAINTENANCE_RT
    };
  
   /**
     * Aggregates the Amount field from Expense records
     * and updates the TotalExpenses__c field on the related WorkOrder.
     *
     * @param expenses List of Expense records to process.
     */
    
    public static void aggregateExpenseOnWorkOrder(List<Expense> expenses) { 
        try {
            // Collect work order IDs from the expenses list
            Set<Id> workOrderIds = new Set<Id>();
            for (Expense expense : expenses) {
                if (expense.WorkOrderId != null) {
                    workOrderIds.add(expense.WorkOrderId);
                }
            }
            
            // Fetch related expenses
            List<Expense> relatedExpenses = [
                SELECT Id, Amount, WorkOrderId 
                FROM Expense 
                WHERE WorkOrderId IN :workOrderIds
            ];

            // Fetch work orders
            List<WorkOrder> workOrders = [
                SELECT Id, TotalExpenses__c 
                FROM WorkOrder 
                WHERE Id IN :workOrderIds 
                AND RecordType.DeveloperName IN :ALLOWED_WO_RECORD_TYPES
            ];

            // Map to store aggregated expenses for each work order
            Map<Id, Decimal> workOrderExpenseMap = new Map<Id, Decimal>();
            for (Expense expense : relatedExpenses) {
                if (expense.WorkOrderId != null) {
                    if (!workOrderExpenseMap.containsKey(expense.WorkOrderId)) {
                        workOrderExpenseMap.put(expense.WorkOrderId, 0);
                    }
                    workOrderExpenseMap.put(expense.WorkOrderId, workOrderExpenseMap.get(expense.WorkOrderId) + expense.Amount);
                }
            }

            // Update total expenses on work orders
            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
            for (WorkOrder wo : workOrders) {
                if (workOrderExpenseMap.containsKey(wo.Id)) {
                    Decimal newTotalExpense = workOrderExpenseMap.get(wo.Id);
                    if (wo.TotalExpenses__c == null) {
                        wo.TotalExpenses__c = 0;
                    }
                    wo.TotalExpenses__c = newTotalExpense;
                    workOrdersToUpdate.add(wo);
                }
            }

            // Perform update if there are work orders to update
            if (!workOrdersToUpdate.isEmpty() && WorkOrder.sObjectType.getDescribe().isUpdateable()) {
                update workOrdersToUpdate;
            } 
        } catch (Exception ex) {
            Logger.logException(ex);
        }
    }
    
   /**
     * Create sharing records for Supervisor,Branch Managers and Mechanic office members
     *
     * @param newList List of SObject records to process.
     */
    
    public Static void createExpenseShareRecord(List<Expense> expenseRecList){
        List<ExpenseShare> listOfExpShare = new List<ExpenseShare>(); 
        Map<Id,ServiceResource> mapOfSrIdVsSr = new Map<Id,ServiceResource>();
        Set<Id> setOfSrOfficeId = new Set<Id>();
        Map<Id,Set<Id>> mapOfExpIdVsUserId = new Map<Id,Set<Id>>();
        Set<Id>setOfSrId = new Set<Id>();
        
        try{
            if(!expenseRecList.IsEmpty() && expenseRecList!= Null){
                //Query to get Office Id of expense record's Service Resource Records
                for(Expense exp:expenseRecList){
                    setOfSrId.add(exp.ServiceResource__c);
                }
                if(!setOfSrId.IsEmpty() && setOfSrId != Null){
                    List<ServiceResource> listOfServiceResourceRec = [SELECT Id,Branch__c FROM ServiceResource WHERE Id In:setOfSrId];
                    if(!listOfServiceResourceRec.IsEmpty() && listOfServiceResourceRec != Null){
                        for(ServiceResource sr:listOfServiceResourceRec){
                            setOfSrOfficeId.add(sr.Branch__c);
                        }
                    }
                }                
            }
            //Map contains Key: Service Resource Id with Service Resource Record
           	if(!setOfSrOfficeId.IsEmpty() && setOfSrOfficeId != Null){
                List<ServiceResource> listOfServiceResource = [select id,relatedrecordid,Branch__c,JobTitle__c from ServiceResource where Branch__c In:setOfSrOfficeId];
                if(!listOfServiceResource.IsEmpty() && listOfServiceResource != Null){
                    for(ServiceResource serviceResObj : listOfServiceResource){
                        if(!mapOfSrIdVsSr.containsKey(serviceResObj.Id)){
                            mapOfSrIdVsSr.put(serviceResObj.Id,serviceResObj);
                        }                    
                    }
                }
                //Query the Office member Id related to Service resource Office from Expense Report
                List<BranchMemberRole__c> listOfOfficeMem= [SELECT Id,Branch__c,InternalResource__r.User__c,BookableResource__r.RelatedRecordId FROM BranchMemberRole__c WHERE Branch__c In: setOfSrOfficeId];
                if(!listOfOfficeMem.IsEmpty() && listOfOfficeMem != Null){
                    //Map contains Key: Office Id with set of Value: Office Members Id's 
                    for(BranchMemberRole__c bmr:listOfOfficeMem){
                        if(bmr.InternalResource__r.User__c != Null){
                            if(!mapOfExpIdVsUserId.containsKey(bmr.Branch__c)){
                                mapOfExpIdVsUserId.put(bmr.Branch__c,new Set<Id>{bmr.InternalResource__r.User__c});
                            }
                            else{
                                Set<Id> setOfUserId = mapOfExpIdVsUserId.get(bmr.Branch__c);
                                setOfUserId.add(bmr.InternalResource__r.User__c);
                                mapOfExpIdVsUserId.put(bmr.Branch__c,setOfUserId);
                            }
                        }
                        else if(bmr.BookableResource__r.RelatedRecordId != Null){
                            if(!mapOfExpIdVsUserId.containsKey(bmr.Branch__c)){
                                mapOfExpIdVsUserId.put(bmr.Branch__c,new Set<Id>{bmr.BookableResource__r.RelatedRecordId});
                            }
                            else{
                                Set<Id> setOfSRUserId = mapOfExpIdVsUserId.get(bmr.Branch__c);
                                setOfSRUserId.add(bmr.BookableResource__r.RelatedRecordId);
                                mapOfExpIdVsUserId.put(bmr.Branch__c,setOfSRUserId);
                            }
                        }
                    }
                }
            }
            if(!expenseRecList.IsEmpty() && expenseRecList!= Null){
                for(Expense exp:expenseRecList){
                    if(exp.ServiceResource__c != Null){
                        listOfExpShare = createRecordOfExpenseShare(exp.Id,mapOfExpIdVsUserId.get(mapOfSrIdVsSr.get(exp.ServiceResource__c).Branch__c));
                    }
                }
            }
            if(!listOfExpShare.IsEmpty() && listOfExpShare!=Null){
                database.insert(listOfExpShare,false);
            }
        } catch(exception e){
            Logger.logException(e);
        }
    }
    
    private static List<ExpenseShare> createRecordOfExpenseShare(string expenseId , Set<Id> setOfUserId){
        List<ExpenseShare> listOfExpenseShare = new List<ExpenseShare>();
		if(!setOfUserId.IsEmpty() && setOfUserId != Null){
			for(Id userId: setOfUserId){
				ExpenseShare  ShareRecObj = new ExpenseShare ();
				ShareRecObj.ParentId = expenseId;
				ShareRecObj.UserOrGroupId = userId;
				ShareRecObj.AccessLevel = 'Edit';
				ShareRecObj.RowCause = Schema.ExpenseShare.RowCause.Manual;
				listOfExpenseShare.add(ShareRecObj);
			}
		}
        return listOfExpenseShare;
    }
}