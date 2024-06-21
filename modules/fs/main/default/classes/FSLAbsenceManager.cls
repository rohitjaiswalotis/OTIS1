public class FSLAbsenceManager {
    
    @InvocableMethod(label='CreateRecurringAbsences' description='Manages the absence of the resources' category='Resource Absence')
    public static void resourceAbsenceFromFlow (List <ResourceabsenceWrapper> absencesToCreate) {
        
        ResourceabsenceWrapper absencesToInsert = absencesToCreate[0];
        List<ResourceAbsence> absenceList = new List<ResourceAbsence>();
        List<ServiceResource> serviceResourceUsersList = new List<ServiceResource>();
        ResourceAbsence absence;
        Integer loopCount=0;
        Integer frequency = 1;
        
        if(absencesToInsert.loggedInSupervisorId!=null){
        	serviceResourceUsersList = [select id,RelatedRecordId,Resource_Manager_ID__c,ResourceType from ServiceResource where Resource_Manager_ID__c =:absencesToInsert.loggedInSupervisorId AND ResourceType='T'];
        }
        
       
        
        if(absencesToInsert.reccurenceType=='Daily'){
            loopCount = (absencesToInsert.endDate.Day() - absencesToInsert.startTime.Day())+1;
        }else if(absencesToInsert.reccurenceType=='Monthly'){
            loopCount = (absencesToInsert.endDate.Month() - absencesToInsert.startTime.Month())+1;
        }else if(absencesToInsert.reccurenceType=='Yearly'){
            loopCount = (absencesToInsert.endDate.Year() - absencesToInsert.startTime.Year())+1;
        }
        
        for(integer i=1; i <=loopCount ; i++) {	
            for(ServiceResource sr : serviceResourceUsersList){
               	absence = new ResourceAbsence();
                absence.Type = absencesToInsert.absenceType;
                absence.Start = absencesToInsert.startTime;  
                absence.End = absencesToInsert.endTime;  
                absence.City = absencesToInsert.city;  
                absence.Country = absencesToInsert.country;  
                absence.State = absencesToInsert.state;  
                absence.Street = absencesToInsert.street;  
                absence.PostalCode = absencesToInsert.postalCode;  
                absence.Description = absencesToInsert.description;  
                absence.Internal_Id__c = absencesToInsert.internalId ;  
                absence.ResourceId = sr.Id;  
                absence.FSL__Approved__c =absencesToInsert.isApproved ; 
                absenceList.add(absence);
                
            }
            if(absencesToInsert.reccurenceType=='Daily'){
                absencesToInsert.startTime = absencesToInsert.startTime.addDays(frequency);
                absencesToInsert.endTime = absencesToInsert.endTime.addDays(frequency);
            }else if(absencesToInsert.reccurenceType=='Monthly'){
                absencesToInsert.startTime = absencesToInsert.startTime.addMonths(frequency);
                absencesToInsert.endTime = absencesToInsert.endTime.addMonths(frequency);
            }else if(absencesToInsert.reccurenceType=='Yearly'){
                absencesToInsert.startTime = absencesToInsert.startTime.addYears(frequency);
                absencesToInsert.endTime = absencesToInsert.endTime.addYears(frequency);
            } 
        }
        system.debug('absenceList size: '+absenceList.size());
        insert absenceList;
        
    }
    public class ResourceabsenceWrapper {
        @InvocableVariable public string absenceType;
        @InvocableVariable public Datetime startTime;
        @InvocableVariable public Datetime endTime;
        @InvocableVariable public string street ;
        @InvocableVariable public string city ;
        @InvocableVariable public string country ;
        @InvocableVariable public string postalCode ;
        @InvocableVariable public string state ;
        @InvocableVariable public string description ;
        @InvocableVariable public string internalId;
        @InvocableVariable public Boolean isApproved ;
        @InvocableVariable public String reccurenceType ;
        @InvocableVariable public DateTime endDate ;
        @InvocableVariable public Id loggedInSupervisorId ;
        
    }
}