/**=========================================================================================
* Author : Anubrata Sanyal
* Version : 01
* Description: Queable Apex to be used upon Resource Deletion
* Created Date : 24-07-2024
* Last Modified Date: 
=========================================================================================*/
public class FSL_AssignedResourceOnDeleteQueable implements Queueable{
    //initializing Global Variable
    public List<AssignedResource> listOfassignedResource;
    
    //initializing Constructor
    public  FSL_AssignedResourceOnDeleteQueable(List<AssignedResource> assignedResource){
        this.listOfassignedResource =assignedResource;
    }
    
/**=================================================================================================
* Method Author : Anubrata Sanyal
* Method Description: Execute method to pass Output from Flow to any other method within the class
====================================================================================================*/
    public void execute(QueueableContext qc){
        //initializing List of SA
        List<ServiceAppointment> listOfSA = new List<ServiceAppointment>();
        for(AssignedResource obj : listOfassignedResource){
            ServiceAppointment sa = new ServiceAppointment (Id =obj.ServiceAppointmentId);
            sa.AssignedServiceResource__c=NULL;
            listOfSA.add(sa);
        }
        if(listOfSA != NULL){
            update listOfSA;
        }
        
    }
}