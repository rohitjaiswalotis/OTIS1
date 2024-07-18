/**=========================================================================================
* Author : 
* Version : 01
* Description: OTIS Route Reassignment Handler Class to store all business logic methods
* Created Date : 02-07-2024
* Last Modified Date: 
=========================================================================================*/
public class FSLRouteReassignmentHandler {
 /**=========================================================================================
* Method Author : Udit Sharma
* Method Description: Invocable method to pass Output from Flow to any other method within the class
=========================================================================================*/    
        
        public class FlowInputs {
            @InvocableVariable public Asset newUnitRecord;
            @InvocableVariable public Asset oldUnitRecord;
        }
    
    @InvocableMethod(label='Get Flow Data for Unit' description='Pass the data from flow to the relevant method.' category='Unit')
    public Static void processData(List<FlowInputs> flowInput){
        System.debug('^^^flowInput'+flowInput);
        List<Asset> assetListNew = new List<Asset>();
        List<Asset> assetListOld = new List<Asset>();

        for(FlowInputs flowInpRec : flowInput){
            if(flowInpRec.newUnitRecord!=null && flowInpRec.oldUnitRecord!=null){
                assetListNew.add(flowInpRec.newUnitRecord);
                assetListOld.add(flowInpRec.oldUnitRecord);
            }
        }
        System.enqueueJob(new FSLRouteReassignmentHandlerQueueable(assetListNew,New Map<Id,Asset>(assetListOld)));
      //  handleRouteReassignmentOperation(assetListNew,New Map<Id,Asset>(assetListOld),null);
    }
}