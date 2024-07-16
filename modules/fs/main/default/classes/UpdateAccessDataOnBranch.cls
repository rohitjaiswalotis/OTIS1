/*
Developed by - Cognizant
Created date - 2/2/2024
LastModified On -3/21/2024
US#951659.This batch class is used to attach the Id of member(related user of member object) and Building which is created or deleted under the related office record.
Field used to store Id of Member in the Json format - Member Access
Field used to store Id of Building in the Json format - Building Access
*/

public with sharing class UpdateAccessDataOnBranch {

    public static void updateBuildingDetails(list<schema.location> locationData,string eventType){
        try{
            list<Branch__c> branchDetailsUpdate = new list<Branch__c>();
            map<id,id> branchVSlocation = new map<id,id>();
            for(schema.location dataVal :locationData){
                if(dataVal.BranchName__c!=null ){ 
                    branchVSlocation.put(dataVal.BranchName__c,dataVal.id);
                }
            }

            for(Branch__c branchObj : getOfficesByIds( branchVSlocation.keyset() )) {
                Integer validBranch = getBranchType(branchObj.BranchType__c);
                switch on validBranch{
                    when 1{
                        if(eventType=='Insert' || eventType=='Delete'){
                            branchDetailsUpdate= BranchDetailsForUpdateBuildingsDetails(branchObj,eventType,branchVSlocation);
                        }
                    }
                }
            }

            updateOffices(branchDetailsUpdate);
        }catch(exception ex){
            Logger.logException(ex);
        }
    }

    public static void updateMemberDetails(list<BranchMemberRole__c> memberData, string eventType){
        try{
            list<Branch__c> branchDetailsUpdate = new list<Branch__c>();
            map<id,id> memberVSbranch= new map<id,id>();
            map<id,id> branchVSresource = new map<id,id>();
            set<id> branchIds = new set<id>();

            for(BranchMemberRole__c dataVal :memberData){
                if(dataVal.Branch__c!=null ){
                    branchIds.add(dataVal.Branch__c);
                    MemberVSbranch.put(dataVal.BookableResource__c,dataVal.Branch__c);
                }
            }

            List<Branch__c> offices = getOfficesByIds(branchIds);

            if ( offices.isEmpty() ) {
                return;
            }

            list<serviceResource>  resourceData=[select id,relatedrecordid from  serviceResource 
                                                 where id IN:memberVSbranch.keySet() WITH SECURITY_ENFORCED];
            for(serviceResource data:resourceData) {
                if(memberVSbranch.containskey(data.id)){
                    branchVSresource.put(memberVSbranch.get(data.id),data.RelatedRecordId);  
                }
            }
            
            for (Branch__c branchObj : offices) {
                Integer validBranch = getBranchType(branchObj.BranchType__c);
                switch on validBranch{
                    when 1{
                        if(eventType=='Insert' || eventType=='Delete'){
                            branchDetailsUpdate= branchDetailsForUpdateMemberMethod(branchObj,eventType,branchVSresource);
                        }
                    }
                }
            }

            updateOffices(branchDetailsUpdate);
        } 
        catch(exception ex){
            Logger.logException(ex);            
        }
    }

    /**
    * @description Searches for FSL-enabled office records by provided IDs.
    * @param officeIds 
    * @return List<Branch__c> 
    **/
    private static List<Branch__c> getOfficesByIds(Set<Id> officeIds) {
        return [
            SELECT Id,
                   BranchType__c,
                   Building_access__c,
                   Member_Access__c
            FROM Branch__c
            WHERE Id IN: officeIds
              AND FSLEnabled__c = TRUE
            WITH SECURITY_ENFORCED
        ];
    }

    public static list<Branch__c> branchDetailsForUpdateMemberMethod(Branch__c branchRecObj,string eventType,map<id,id>branchVSresourceMap){
        try{
            list<Branch__c> branchDetails1 = new list<Branch__c>();
            string buildingAccess;
            string addMember;
            string removeMember;
            integer haveAccess;
            haveAccess= checkDataAccess(branchRecObj.Member_Access__c);
             system.debug('-branchRecObj.Member_Access__c-'+branchRecObj.Member_Access__c);
             system.debug('-haveAccess-'+haveAccess);
            switch on haveAccess{
                when 1{
                    Map<String, Object> memberJson=new Map<String, Object>();
                    memberJson = (Map<String, Object>)JSON.deserializeUntyped(branchRecObj.Member_Access__c);
                     system.debug('-memberJson-'+memberJson);
                    string getMemberCase=getMemberData(memberJson);
                    system.debug('-getMemberCase-'+getMemberCase);
                    
                    switch on getMemberCase{
                        when 'Case1'{ 
                            switch on eventType{
                                when 'Insert'{
                                    removeMember=string.valueof(memberJson.get('removeMember'));  
                                    addMember=string.valueof(memberJson.get('addMember'));
                                    addMember=addMember.removeend('"');
                                    addMember=(branchVSresourceMap.containsKey(branchRecObj.id))?(addMember+','+branchVSresourceMap.get(branchRecObj.id)):addMember;                    
                                }
                                when 'Delete'{
                                    addMember=string.valueof(memberJson.get('addMember'));
                                    removeMember=string.valueof(memberJson.get('removeMember'));  
                                    removeMember=removeMember.removeend('"');
                                    removeMember=(branchVSresourceMap.containsKey(branchRecObj.id))?(removeMember+','+branchVSresourceMap.get(branchRecObj.id)):removeMember;    
                                }
                            }
                        }
                        when 'Case2'{
                            switch on eventType{
                                when 'Insert'{
                                    removeMember=string.valueof(memberJson.get('removeMember'));  
                                    addMember=(branchVSresourceMap.containsKey(branchRecObj.id))?branchVSresourceMap.get(branchRecObj.id):addMember;   
                                }                                       
                                when 'Delete'{
                                    removeMember=string.valueof(memberJson.get('removeMember'));  
                                    removeMember=removeMember.removeend('"');
                                    removeMember=(branchVSresourceMap.containsKey(branchRecObj.id))?(removeMember+','+branchVSresourceMap.get(branchRecObj.id)):removeMember;    
                                }
                            }
                            
                        }
                        when 'Case3'{
                            switch on eventType{
                                when 'Insert'{
                                    addMember=(branchVSresourceMap.containsKey(branchRecObj.id))?branchVSresourceMap.get(branchRecObj.id):addMember;  
                                }
                                when 'Delete'{
                                    removeMember=(branchVSresourceMap.containsKey(branchRecObj.id))?branchVSresourceMap.get(branchRecObj.id):removeMember; 
                                }
                            }
                        }
                        when 'Case4'{
                            switch on eventType{
                                when 'Insert'{
                                    addMember=string.valueof(memberJson.get('addMember'));
                                    addMember=addMember.removeend('"');
                                    addMember=(branchVSresourceMap.containsKey(branchRecObj.id))?(addMember+','+branchVSresourceMap.get(branchRecObj.id)):addMember;                    
                                }
                                when 'Delete'{
                                    addMember=string.valueof(memberJson.get('addMember'));
                                    removeMember=(branchVSresourceMap.containsKey(branchRecObj.id))?branchVSresourceMap.get(branchRecObj.id):removeMember; 
                                }
                            }
                        }
                    }
                }    
                
                when 0{ 
                    switch on eventType{
                        when 'Insert'{
                            addMember=branchVSresourceMap.get(branchRecObj.id);
                        }
                        when 'Delete'{
                            removeMember=branchVSresourceMap.get(branchRecObj.id);
                        }
                    }
                    buildingAccess='{"addMember": "'+(addMember!=null?addMember:'')+'","removeMember":"'+(removeMember!=null?removeMember:'')+'"}';
                }
            }
            
            buildingAccess='{"addMember": "'+(addMember!=null?addMember:'')+'","removeMember":"'+(removeMember!=null?removeMember:'')+'"}';
            branchRecObj.Member_Access__c=buildingAccess;
            branchDetails1.add(branchRecObj);
            // database.update(branchDetails1);
            return branchDetails1;
            
        }catch(Exception ex){
            Logger.logException(ex);
            return null;
        }
    }

    public static  list<Branch__c> branchDetailsForUpdateBuildingsDetails(Branch__c branchRecObj,string eventType,map<id,id>branchVSlocationMap){
        try{
            list<Branch__c> branchDetails1 = new list<Branch__c>();
            string buildingAccess;
            string addBuilding;
            string removeBuilding;
            integer haveAccess;
            haveAccess= checkDataAccess(branchRecObj.Building_access__c);
             system.debug('-branchRecObj.Building_access__c-'+branchRecObj.Building_access__c);
            system.debug('-haveAccess-'+haveAccess);
            switch on haveAccess{
                when 1{
                    Map<String, Object> buildingJson=new Map<String, Object>();
                    buildingJson = (Map<String, Object>)JSON.deserializeUntyped(branchRecObj.Building_access__c); 
                    string getBuildingCase=getbuildingData(buildingJson);
                    system.debug('-getBuildingCase-'+getBuildingCase);
                    switch on getBuildingCase{
                        when 'Case1'{ 
                            switch on eventType{
                                when 'Insert'{
                                    removeBuilding=string.valueof(buildingJson.get('removeBuilding'));  
                                    addBuilding=string.valueof(buildingJson.get('addBuilding'));
                                    addBuilding=addBuilding.removeend('"');
                                    addBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?(addBuilding+','+branchVSlocationMap.get(branchRecObj.id)):addBuilding;                    
                                }
                                when 'Delete'{
                                    addBuilding=string.valueof(buildingJson.get('addBuilding'));
                                    removeBuilding=string.valueof(buildingJson.get('removeBuilding'));  
                                    removeBuilding=removeBuilding.removeend('"');
                                    removeBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?(removeBuilding+','+branchVSlocationMap.get(branchRecObj.id)):removeBuilding;    
                                }
                            }
                        }
                        when 'Case2'{
                            switch on eventType{
                                when 'Insert'{
                                    removeBuilding=string.valueof(buildingJson.get('removeBuilding'));  
                                    addBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?branchVSlocationMap.get(branchRecObj.id):addBuilding;   
                                }                                       
                                when 'Delete'{
                                    removeBuilding=string.valueof(buildingJson.get('removeBuilding'));  
                                    removeBuilding=removeBuilding.removeend('"');
                                    removeBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?(removeBuilding+','+branchVSlocationMap.get(branchRecObj.id)):removeBuilding;    
                                }
                            }
                            
                        }
                        when 'Case3'{ 
                            switch on eventType{
                                when 'Insert'{
                                    addBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?branchVSlocationMap.get(branchRecObj.id):addBuilding;  
                                }
                                when 'Delete'{
                                    removeBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?branchVSlocationMap.get(branchRecObj.id):removeBuilding; 
                                }
                            }
                        }
                        when 'Case4'{
                            switch on eventType{
                                when 'Insert'{
                                    addBuilding=string.valueof(buildingJson.get('addBuilding'));
                                    addBuilding=addBuilding.removeend('"');
                                    addBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?(addBuilding+','+branchVSlocationMap.get(branchRecObj.id)):addBuilding;                    
                                }
                                when 'Delete'{
                                    addBuilding=string.valueof(buildingJson.get('addBuilding'));
                                    removeBuilding=(branchVSlocationMap.containsKey(branchRecObj.id))?branchVSlocationMap.get(branchRecObj.id):removeBuilding; 
                                }
                            }
                        }
                    } 
                    
                    buildingAccess='{"addBuilding": "'+(addBuilding!=null?addBuilding:'')+'","removeBuilding":"'+(removeBuilding!=null?removeBuilding:'')+'"}';
                    
                }
                when 0{
                    switch on eventType{
                        when 'Insert'{
                            addBuilding=branchVSlocationMap.get(branchRecObj.id);
                        }
                        when 'Delete'{
                            removeBuilding=branchVSlocationMap.get(branchRecObj.id);
                        }
                    }
                    buildingAccess='{"addBuilding": "'+(addBuilding!=null?addBuilding:'')+'","removeBuilding":"'+(removeBuilding!=null?removeBuilding:'')+'"}';
                }
            }
            branchRecObj.Building_access__c=buildingAccess;
            branchDetails1.add(branchRecObj);
            // database.update(branchDetails1);
            return branchDetails1;
            
        }catch(Exception ex){
            Logger.logException(ex);
            return null;
        }
    }

    public static string getMemberData( Map<String, Object> memberJson){
        string getMemberCase;
        string removeMember= (memberJson.get('removeMember')!=null && memberJson.get('removeMember')!='')?string.valueof(memberJson.get('removeMember')):'null';
        string addMember =(memberJson.get('addMember')!=null && memberJson.get('addMember')!='')?string.valueof(memberJson.get('addMember')):'null';
        return getMemberCase=(removeMember!='null' && addMember !='null')?'Case1':
        (removeMember != 'null' && addMember=='null')?'Case2':
        (removeMember == 'null' && addMember=='null')? 'Case3':  
        (removeMember == 'null' && addMember!='null')?'Case4':'';
    }
    
    public static string getbuildingData( Map<String, Object> buildingJson){
        string getBuildingCase;
        string removeBuilding= (buildingJson.get('removeBuilding')!=null && buildingJson.get('removeBuilding')!='')?string.valueof(buildingJson.get('removeBuilding')):'null';
        string addBuilding =(buildingJson.get('addBuilding')!=null && buildingJson.get('addBuilding')!='')?string.valueof(buildingJson.get('addBuilding')):'null';
        return getBuildingCase=(removeBuilding!='null' && addBuilding !='null')?'Case1':
        (removeBuilding != 'null' && addBuilding=='null')?'Case2':
        (removeBuilding == 'null' && addBuilding=='null')? 'Case3':  
        (removeBuilding == 'null' && addBuilding!='null')?'Case4':'';
    }
    
    public Static Integer getBranchType(String branchType){
        return branchType==UTIL_Constants.OFFICE_TYPE_BRANCH ||branchType==UTIL_Constants.OFFICE_TYPE_GBO?1:0;
    }

    public Static Integer checkDataAccess(String access){
        return (access!=null  && access!='')?1:0;  
    }


    /**
    * @description Updates provided office (Branch__c) records with CRUD validations.
    * @param offices 
    **/
    private static void updateOffices(List<Branch__c> offices) {
        if ( BaseUtilities.isNullOrEmpty(offices) || !Branch__c.SObjectType.getDescribe().isUpdateable() ) {
            return; 
        }

        update offices;
    }

}