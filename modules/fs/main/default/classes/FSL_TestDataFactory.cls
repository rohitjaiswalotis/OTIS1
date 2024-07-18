/**=========================================================================================
    @Description: FSL Test Data class for generating test data, common records
    =========================================================================================*/
public class FSL_TestDataFactory {
	
    public Static ServiceTerritoryMember createServiceTerritoryMember(Id OperatingHours,Id ServiceResource,Id ServiceTerritory,Datetime EffectiveStart)
    {
        ServiceTerritoryMember temp = new ServiceTerritoryMember(
            OperatingHoursId = OperatingHours,
            ServiceResourceId = ServiceResource,
            ServiceTerritoryId = ServiceTerritory,
            EffectiveStartDate = EffectiveStart
        );
        return temp;    
    }
    public Static AssignedResource createAssignedResource(Id ServiceResource,Id ServiceAppointment)
    {
        AssignedResource temp = new AssignedResource(
            ServiceResourceId = ServiceResource,
            ServiceAppointmentId = ServiceAppointment
        );
        return temp;    
    }
    public Static WorkPlanTemplate createWorkPlanTemplate(String name,String description,Integer relExecutionOrder,Boolean active)
    {
        WorkPlanTemplate temp = new WorkPlanTemplate(
            Name = name,
            Description = description,
            RelativeExecutionOrder=relExecutionOrder,
            IsActive=active        
        );
        return temp;    
    }
    public Static WorkStepTemplate createWorkStepTemplate(String name,String description,Boolean majorTask,Boolean active)
    {
        WorkStepTemplate temp = new WorkStepTemplate(
            Name = name,
            Description = description,
            MajorTask__c=majorTask,
            IsActive=active        
        );
        return temp;    
    }
	public Static WorkPlanTemplateEntry createWorkPlanTemplateEntry(Id WorkPlanTemplate,Id WorkStepTemplate,Integer executionOrder)
    {
        WorkPlanTemplateEntry temp = new WorkPlanTemplateEntry(
            WorkPlanTemplateId = WorkPlanTemplate,
            WorkStepTemplateId = WorkStepTemplate,
            ExecutionOrder = executionOrder       
        );
        return temp;    
    }
    public Static WorkPlanSelectionRule createWorkPlanSelectionRule(Id WorkPlanTemplate,Id WorkType,Boolean active)
    {
        WorkPlanSelectionRule temp = new WorkPlanSelectionRule(
            WorkPlanTemplateId = WorkPlanTemplate,
            WorkTypeId = WorkType,
            IsActive = active       
        );
        return temp;    
    }
    public Static WorkPlan createWorkPlan(String Name,Id workOrder)
    {
        WorkPlan temp = new WorkPlan(
            Name = Name,
            WorkOrderId = workOrder       
        );
        return temp;    
    }
    public static Entitlement createEntitlement(String name,Id accountId, Id unitId){
        Entitlement entitlement = new Entitlement(
            Name=name,
            AccountId=accountId,
            AssetId= unitId,
            StartDate=Date.Today(),
            EndDate=Date.Today().addYears(1)
        );
        return entitlement;
    }
    
    public static ServiceContract createServiceContract(String name,Id accountId, Id unitId, Id priceBookId){
        ServiceContract sc = new ServiceContract(
            Name=name,
            AccountId=accountId,
            Unit__c= unitId,
            Pricebook2Id = priceBookId,
            StartDate=Date.Today(),
            EndDate=Date.Today().addYears(1)
        );
        return sc;
    }
    
    public static ContractLineItem__c createContractLineItemsCustom(String name,Id assetId,Id contractId,String optionCategory){
        ContractLineItem__c contractLineItemCustom = new ContractLineItem__c(
            Name=name,
            Contract__c=contractId,
            Unit__c=assetId,
            FS_OptionCategory__c= optionCategory
        );
        return contractLineItemCustom;
    }
    
    public static ContractLineItem createContractLineItemsStandard(String name,Id unitId, Id salesContractLineItem,Id priceBookEntry,Id serviceContractId){
        ContractLineItem contractLineItem = new ContractLineItem(
            Name__c=name,
            AssetId=unitId,
            PricebookEntryId=priceBookEntry,
            UnitPrice=2000,
            Quantity=3,
            FS_SalesContractLineItem__c= salesContractLineItem,
            ServiceContractId = serviceContractId
        );
        return contractLineItem;
    }
    
    
    public static Contract createContract(String name,String contractNumber,Id accountId){
        Contract contract = new Contract(
            Name=name,
            Contract_Number__c = contractNumber,
            AccountId=accountId
        );
        return contract;
    }
    
    public static PricebookEntry createPricebookEntry (Product2 prod) {
	    PricebookEntry one = new PricebookEntry();
	    one.pricebook2Id = Test.getStandardPricebookId();
	    one.product2id = prod.id;
	    one.unitprice = 1249.0;
	    one.isactive = true;
	    return one;
	}
    
    public static Product2 createProduct(String name) {
        Product2 producto =new Product2();
        producto.Name=name;
        producto.productCode='1234';
        producto.isActive = true;
        return  producto;
    }
    public static Contact createContactwithBusinessPhone(Id accountId, String lastName,Integer businessPhn) {
        Contact temp = new Contact(
                AccountId = accountId,
                LastName = lastName,Phone = '9898786559'
        );
        return temp;
    }
    
    //Return Otis Expense Setting record
    public static OTIS_Expense_Setting__c createOtisExpenseSetting(String name, String company, Decimal mileage, Decimal zone, Decimal cartage, Decimal perDiem, Decimal other){
        OTIS_Expense_Setting__c otisExpSet = new OTIS_Expense_Setting__c();
        otisExpSet.Name = name;
        otisExpSet.Company__c = company;
        otisExpSet.FS_Zone__c = zone;
        otisExpSet.FS_Cartage__c=cartage;
        otisExpSet.FS_Per_Diem__c=perDiem;
        otisExpSet.FS_Other__c=other;
        otisExpSet.FS_Mileage__c=mileage;
        return otisExpSet;
    }
     
    //Retuns list of Expense records
    public static List<Expense> createExpense(Id serviceResource, Date transactionDate, String expenseCategory, Decimal amount, Integer numberOfRecs){
        List<Expense> expenseRec = new List<Expense>();
        for(Integer i=0;i< numberOfRecs;i++){
            Expense exp = new Expense();
            exp.ServiceResource__c = serviceResource;
            exp.TransactionDate=transactionDate;
            exp.ExpenseCategory__c = expenseCategory;
            exp.Amount=amount;
            expenseRec.add(exp);
        }
        return expenseRec;
    }
    
    //Returns Holiday Adjustment record
    public static Holiday_Adjustment__c createHolidayAdjustment(Date originalStart, Date originalEnd, Date adjustedStart, Date adjustedEnd, Boolean processed){
        Holiday_Adjustment__c hAdj = new Holiday_Adjustment__c();
        hAdj.Original_Start_Date__c = originalStart;
        hAdj.Original_End_Date__c = originalEnd;
        hAdj.Adjusted_Start_Date__c = adjustedStart;
        hAdj.Adjusted_End_Date__c = adjustedEnd;
        hAdj.Processed__c = processed;
        return hAdj;
    }
    
    //Returns Expense Report Entry Record
    public static ExpenseReportEntry createExpenseReportEntry(Id expenseId, Id expenseReportId){
        ExpenseReportEntry ere = new ExpenseReportEntry();
        ere.ExpenseId = expenseId;
        ere.ExpenseReportId = expenseReportId;
        return ere;
    }

    public static WorkOrder createWorkOrder(
        Id accountId, Id contactId, Id caseId, Id assetId, Id serviceTerritoryId, Id branchId,
        Datetime svcReqAssignedDateTime, Id recordTypeId, Id workTypeId
    ) {

        WorkOrder workOrder = new WorkOrder(
            AccountId = accountId,
            ContactId = contactId,
            CaseId = caseId,
            AssetId = assetId,
            ServiceTerritoryId = serviceTerritoryId,
            Branch__c = branchId,
            WorkTypeId = workTypeId,
            SvcReqAssignedDateTime__c = svcReqAssignedDateTime,
            RecordTypeId = recordTypeId
        );

        return workOrder;
    }
    
    public static List<WorkOrder> createWorkOrders(
        Id accountId, Id contactId, Id caseId, Id assetId, Id serviceTerritoryId, Id branchId,
        Datetime svcReqAssignedDateTime, Id recordTypeId,Id workTypeId, Integer numberOfRecords
    ) {

        List<WorkOrder> workOrders = new List<WorkOrder>();

        for (Integer i = 0; i < numberOfRecords; i++) {
            workOrders.add(
                FSL_TestDataFactory.createWorkOrder(
                    accountId, contactId, caseId, assetId, serviceTerritoryId, branchId, svcReqAssignedDateTime,
                    recordTypeId,workTypeId
                )
            );
        }

        return workOrders;
    }
    
    public static WorkPlan createWorkPlan(String name,Id mechanincId,Id workOrderId){
        WorkPlan workplan = new WorkPlan(
            Name=name,
            OwnerId = mechanincId,
            WorkOrderId=workOrderId
        );
        return workplan;
    }
    
    public static WorkStep createWorkSteps(String name,Id workPlanId,String status,Boolean majorTask){
        WorkStep workStepObj = new WorkStep(
            Name=name,
            MajorTask__c = majorTask,
            WorkPlanId=workPlanId,
            Status = status
        );
        return workStepObj;
    }
    public static List<TimeSheetEntry> createTimeSheetEntry(String Status, Id TimeSheetId, DateTime EndTime , DateTime StartTime , Integer numberOfRecords ) {
        List<TimeSheetEntry> timeSheetEntrys = new List<TimeSheetEntry>();
 
        for (Integer i = 0; i < numberOfRecords; i++) {
            TimeSheetEntry tse = new TimeSheetEntry();
            tse.StartTime = StartTime;
            tse.EndTime = EndTime;
            tse.Status = Status;tse.TimeSheetId = TimeSheetId;
            timeSheetEntrys.add(tse);
        }
 
        return timeSheetEntrys;
    }
}