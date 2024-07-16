/*=======================================================================================================
Developed by - Cognizant
Created date - 09/07/2024
Description: Class is to create the Expense report share record for Supervisor, Branch manager and office members.
==========================================================================================================*/
public class FSL_ExpenseReportTriggerHandlerService {
	
    public Static void createExpenseReportShare(List<ExpenseReport> expenseRepRecList){
        try{
            List<ExpenseReportShare> sharesToInsertList = new List<ExpenseReportShare>();
            List<ExpenseReportShare> expenseReportOfcMemShare = new List<ExpenseReportShare>();
            Map<Id,ServiceResource> idVsResourceMap = new Map<Id,ServiceResource>();
            Set<Id> setOfOfficeId = new Set<Id>();
            Set<Id> setOfSerResId = new Set<Id>();
            Map<Id,Set<Id>> mapOfExpRepIdVsUserId = new Map<Id,Set<Id>>();
            
            if(!expenseRepRecList.IsEmpty() && expenseRepRecList != Null){
                for(ExpenseReport exp: expenseRepRecList){
                    setOfSerResId.add(exp.Service_Resource__c);
                }
                if(!setOfSerResId.IsEmpty() && setOfSerResId != Null){
                    List<ServiceResource> listOfServiceResource = [SELECT Id,Branch__c FROM ServiceResource WHERE Id In:setOfSerResId];
                    if(!listOfServiceResource.IsEmpty() && listOfServiceResource != Null){
                        for(ServiceResource sr:listOfServiceResource){
                            setOfOfficeId.add(sr.Branch__c);
                        }
                    }
                }
            }
            if(!setOfOfficeId.IsEmpty() && setOfOfficeId != Null){
                List<ServiceResource> listOfServiceResRecords = [SELECT Id,relatedrecordid,Branch__c,JobTitle__c FROM ServiceResource where Branch__c In: setOfOfficeId];
				if(!listOfServiceResRecords.IsEmpty() && listOfServiceResRecords!=Null){
                    for(ServiceResource serviceResObj : listOfServiceResRecords){
                        idVsResourceMap.put(serviceResObj.Id,serviceResObj);
                    }
                }
                //Query the Office member Id related to Service resource Office from Expense Report
                List<BranchMemberRole__c> listOfOfficeMem= [SELECT Id,Branch__c,InternalResource__r.User__c,BookableResource__r.RelatedRecordId FROM BranchMemberRole__c WHERE Branch__c In: setOfOfficeId];
                //Map contains Key: Office Id with set of Value: Office Members Id's 
                for(BranchMemberRole__c bmr:listOfOfficeMem){
                    if(bmr.InternalResource__r.User__c != Null){
                        if(!mapOfExpRepIdVsUserId.containsKey(bmr.Branch__c)){
                            mapOfExpRepIdVsUserId.put(bmr.Branch__c,new Set<Id>{bmr.InternalResource__r.User__c});
                        }
                        else{
                            Set<Id> setOfUserId = mapOfExpRepIdVsUserId.get(bmr.Branch__c);
                            setOfUserId.add(bmr.InternalResource__r.User__c);
                            mapOfExpRepIdVsUserId.put(bmr.Branch__c,setOfUserId);
                        }
                    }
                    else if(bmr.BookableResource__r.RelatedRecordId != Null){
                        if(!mapOfExpRepIdVsUserId.containsKey(bmr.Branch__c)){
                            mapOfExpRepIdVsUserId.put(bmr.Branch__c,new Set<Id>{bmr.BookableResource__r.RelatedRecordId});
                        }
                        else{
                            Set<Id> setOfSRUserId = mapOfExpRepIdVsUserId.get(bmr.Branch__c);
                            setOfSRUserId.add(bmr.BookableResource__r.RelatedRecordId);
                            mapOfExpRepIdVsUserId.put(bmr.Branch__c,setOfSRUserId);
                        }
                    }
            	}
            }
            for(ExpenseReport expense : expenseRepRecList){
                If(idVsResourceMap.containsKey(expense.Service_Resource__c)){
                  //share record with service resource  
                   ExpenseReportShare  expenRepObj = createRecordOfExpenseRepShare(expense.id,idVsResourceMap.get(expense.Service_Resource__c).relatedrecordid);
                   sharesToInsertList.add(expenRepObj);
                }
                if(expense.Supervisor__c != null ){
                    ExpenseReportShare  expenRepObj= createRecordOfExpenseRepShare( expense.id, expense.Supervisor__c);
                    sharesToInsertList.add(expenRepObj);
               	}
                if(expense.Branch_Manager__c != null){
                    ExpenseReportShare  expenRepObj1= createRecordOfExpenseRepShare(expense.id,expense.Branch_Manager__c);
                    sharesToInsertList.add(expenRepObj1);
                }
                //Share expense report record with Service Resource's Office Member
                if(expense.Service_Resource__c != Null && idVsResourceMap.get(expense.Service_Resource__c).JobTitle__c == 'Helper'){
                    expenseReportOfcMemShare = createRecordOfExpenseRepShareBranchMem(expense.id,mapOfExpRepIdVsUserId.get(idVsResourceMap.get(expense.Service_Resource__c).Branch__c));
                }
            }
            
            // Insert the sharing records for give Permission.
            if (!sharesToInsertList.isEmpty()) {
                database.insert(sharesToInsertList,false);
            }
            if(!expenseReportOfcMemShare.IsEmpty() && expenseReportOfcMemShare!=Null){
                database.insert(expenseReportOfcMemShare,false);
            }
        }
        catch(exception ex){
            Logger.logException(ex);
        }
    }
    
    // This Method is used to create Permission Record for give Access to SuperVisor and manager on Expense Report.
    private  Static  ExpenseReportShare createRecordOfExpenseRepShare(string expenseId , string userId){
        ExpenseReportShare ShareRecObj = new ExpenseReportShare();
        ShareRecObj.ParentId = expenseId;
        ShareRecObj.UserOrGroupId = userId;
        ShareRecObj.AccessLevel = 'Edit';
        ShareRecObj.RowCause = Schema.ExpenseReportShare.RowCause.Manual;
        return ShareRecObj;
        
    }
    //This Method is used to create Record share Access to Office Members from expense report's Service Resource Office
    private  Static List<ExpenseReportShare> createRecordOfExpenseRepShareBranchMem(string expenseId , Set<Id> setOfUserId){
            List<ExpenseReportShare> listOfExpenseShare = new List<ExpenseReportShare>();
            if(!setOfUserId.ISEmpty() && setOfUserId != Null){
                for(Id userId: setOfUserId){
                    ExpenseReportShare ShareRecObj = new ExpenseReportShare();
                    ShareRecObj.ParentId = expenseId;
                    ShareRecObj.UserOrGroupId = userId;
                    ShareRecObj.AccessLevel = 'Edit';
                    ShareRecObj.RowCause = Schema.ExpenseReportShare.RowCause.Manual;
                    listOfExpenseShare.add(ShareRecObj);
        		}
            }
            return listOfExpenseShare;
    }
}