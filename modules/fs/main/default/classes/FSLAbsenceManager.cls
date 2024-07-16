/**=========================================================================================
* Author : Aritra Bhattacharyya
* Version : 01
* Description:  To create Absence for multiple service resources in bulk
* Created Date : 24/06/2024
=========================================================================================*/
public class FSLAbsenceManager {
   // @InvocableVariable public list<string> ids ;
    // Invocable method definition
    @InvocableMethod(label='CreateRecurringAbsences' description='Manages the absence of the resources' category='Resource Absence')
    public static void resourceAbsenceFromFlow (List<ResourceabsenceWrapper> absencesToCreate) {
        // Extract the first element from the input list
        ResourceabsenceWrapper absencesToInsert = absencesToCreate[0];
        system.debug('absencesToInsert'+absencesToInsert);
        // List to hold ResourceAbsence records to be inserted
        List<ResourceAbsence> absenceList = new List<ResourceAbsence>();
        // List to store ServiceResource records based on criteria
        List<ServiceResource> serviceResourceUsersList = new List<ServiceResource>();
        // Placeholder for ResourceAbsence object
        ResourceAbsence absence;
        // Variables for loop control and frequency of recurrence
        Integer loopCount = 0;
        Integer frequency = 1;
        try{
            // Query ServiceResource records based on supervisor ID if provided
            if (absencesToInsert.loggedInSupervisorId != null) {
                serviceResourceUsersList = [SELECT Id, RelatedRecordId, Resource_Manager_ID__c, ResourceType 
                                            FROM ServiceResource 
                                            WHERE 
                                            id=:absencesToInsert.ids
                                            ];
            }

            // Determine the number of iterations based on recurrence type
            switch on absencesToInsert.reccurenceType {
                when NULL {
                    loopCount = Integer.valueOf((absencesToInsert.endDate.getTime() - absencesToInsert.startTime.getTime())/(1000*60*60*24)+1);
                }
                when 'Daily' {
                    loopCount = Integer.valueOf((absencesToInsert.endDate.getTime() - absencesToInsert.startTime.getTime())/(1000*60*60*24)+1);
                }
                when 'Monthly' {
                    loopCount = (absencesToInsert.endDate.Month() - absencesToInsert.startTime.Month()) + 1;
                }
               when 'Weekly' {
                   loopCount = Integer.valueOf(((absencesToInsert.endDate.getTime() - absencesToInsert.startTime.getTime())/(1000*60*60*24))/7)+1;
                }
            }
            system.debug('loopcount'+loopCount);
            // Loop to create ResourceAbsence records
            for (Integer i = 1; i <= loopCount; i++) {
                // Iterate over each ServiceResource to create absence records
                for (ServiceResource sr : serviceResourceUsersList) {
                    absence = new ResourceAbsence();
                    // Populate fields of ResourceAbsence from the wrapper object
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
                    absence.FSL__Approved__c = absencesToInsert.isApproved;
                    absenceList.add(absence); // Add created absence to the list
                } 
                // Update start and end times based on recurrence type for the next iteration
                switch on absencesToInsert.reccurenceType {
                    when 'Daily' {
                        absencesToInsert.startTime = absencesToInsert.startTime.addDays(frequency);
                        absencesToInsert.endTime = absencesToInsert.endTime.addDays(frequency);
                    }
                    when 'Monthly' {
                        absencesToInsert.startTime = absencesToInsert.startTime.addMonths(frequency);
                        absencesToInsert.endTime = absencesToInsert.endTime.addMonths(frequency);
                    }
                    when 'Weekly' {
                        absencesToInsert.startTime = absencesToInsert.startTime.addYears(7*frequency);
                        absencesToInsert.endTime = absencesToInsert.endTime.addYears(7*frequency);
                    }
                }
            }
            // Insert all created ResourceAbsence records
            if(absenceList!=null){
                insert absenceList;
            }
        }catch(Exception e){
            Logger.logException(e);
        }
    }
    // Inner class to define the structure of input data
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
        @InvocableVariable public list<string> ids ;
    }
}