/**=========================================================================================
* Author : Aditya Kannaujia
* Version : 01
* Description: Asset Service Class to store all business logic methods
* Created Date : 01-08-2024
=========================================================================================*/
public inherited sharing class FSL_AssetService {
    
    /*
* @Description:Method to query the SA where Unit in updated Asset Ids and Status NOT In Completed , Canceled
* @Param : Set of updated Asset Ids , Canceled Status string , Completed Status String
*/    
    public static List<ServiceAppointment> getUnitAddressFromSA(Set<Id> updateAssetIds,String statusCanceled,String statusCompleted){
        //Fetch the Queryhelper record
        FSL_QueryHelper__mdt queryHelperRecord = FSL_AssetHandler.getQueryMetadata.get('Get_ServiceAppointmentWithWOId'); 
        //Query formation
        String soqlQuery = 'SELECT ' + queryHelperRecord.Field_API_Names__c + ' FROM ' + queryHelperRecord.sObject__c + ' WHERE Unit__c IN :updateAssetIds AND Status NOT IN (\''+statusCanceled +'\',\'' + statusCompleted +'\')';
        return Database.query(soqlQuery);
    } 
    
    /**
* @description Update the SA's Lat and Long associated with Asset when the Asset Lat and Long gets updated
* @param New Map of Id and Asset , Old Map of Id and Asset 
*/
    
    public static void updateSArecordsFromUnit(Map<Id,Asset> newMap ,Map<Id,Asset> oldMap){
        String statusCanceled = FSLConstantClass.SERVICE_APPOINTENT_STATUS_CANCELED;
        String statusCompleted = FSLConstantClass.SERVICE_APPOINTENT_STATUS_COMPLETED;
        try{
            Set<Id> updateAssetIds = new Set<Id>();
            for(Id assetId: newMap.keySet()){    
                Asset newAsset = newMap.get(assetId);
                Asset oldAsset =  oldMap.get(assetId);
                if((newAsset.Latitude  != oldAsset.Latitude) || (newAsset.Longitude != oldAsset.Longitude)){
                    updateAssetIds.add(assetId);
                }
            }
            if(!updateAssetIds.isEmpty()){
                List<ServiceAppointment> saList = FSL_AssetService.getUnitAddressFromSA(updateAssetIds,statusCanceled,statusCompleted);
                List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
                
                for(ServiceAppointment sa : saList){
                    Asset asset = newMap.get(sa.Unit__c);
                    sa.Latitude = asset.Latitude;
                    sa.Longitude = asset.Longitude;
                    saToUpdate.add(sa);
                }
                if(!saToUpdate.isEmpty()){
                    update saToUpdate;
                }
            }
        }catch(Exception ex){
            Logger.logException(ex);
        }
        
    }
    
}