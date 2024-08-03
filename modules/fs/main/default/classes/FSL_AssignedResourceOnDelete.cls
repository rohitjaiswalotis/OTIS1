/**=========================================================================================
* Author : Anubrata Sanyal
* Version : 01
* Description: Invocable Method to use in Flow : Assigned Resource Flow upon Delete
* Created Date : 24-07-2024
* Last Modified Date: 
=========================================================================================*/
public class FSL_AssignedResourceOnDelete {
 	//Declare Wrapper Class to store inputs from Flow
    public class FlowInputs {
        @InvocableVariable public AssignedResource assResource;
    }

/**=================================================================================================
* Method Author : Anubrata Sanyal
* Method Description: Invocable method to pass Output from Flow to any other method within the class
*Param : List of FlowInputs
====================================================================================================*/    
   
    @invocableMethod(label='Get Flow Data for Assigned Resource' description='Pass the data from flow to the relevant method.' category='Assigned Resource')
    public static void deleteAssignedResource(List<FlowInputs> flowInput){
		//Initializing List of Assigned Resource
        List<AssignedResource> listOfAssignedResource = new List<AssignedResource>();
        for(FlowInputs flowInpRec : flowInput){
            if(flowInpRec.assResource !=null){
                listOfAssignedResource.add(flowInpRec.assResource);
            }
        }
        if (listOfAssignedResource != NULL){
            System.enqueueJob(new FSL_AssignedResourceOnDeleteQueable(listOfAssignedResource));
        }
    }
}