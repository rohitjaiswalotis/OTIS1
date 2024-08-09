/**=========================================================================================
* Author : Aditya Kannaujia
* Version : 01
* Description: Asset Handler Class to store all business logic methods
* Created Date : 01-08-2024
=========================================================================================*/
public without sharing class FSL_AssetHandler extends TriggerHandler{
    
    public static Map<String,FSL_QueryHelper__mdt> getQueryMetadata = new Map<String,FSL_QueryHelper__mdt>();
    
    public FSL_AssetHandler(){
        if(getQueryMetadata.isEmpty()){
            getQueryMetadata = new Map<String,FSL_QueryHelper__mdt>(FSLUtility.getAllRecordQueryHelperMetadata());
        }
        
    }	
     /*
    * @Description:Method For After Insert
    * @Param : Trigger.newMap and Trigger.oldMap
    */
   /* public override void afterUpdate(Map<Id,SObject> newMap, Map<Id,SObject> oldMap){
        Map<Id,Asset> newAssetMap = (Map<Id,Asset>) newMap;
        Map<Id,Asset> oldAssetMap = (Map<Id,Asset>) oldMap;
        //Invoke this method when the GeoLocation get updated on Asset record
        FSL_AssetService.updateSArecordsFromUnit(newAssetMap,oldAssetMap);
    
}*/
}