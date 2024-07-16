public class FSLRouteSTMOperation {
    public class FlowInputs {
        @InvocableVariable public String userId;
        @InvocableVariable public String operationType;
        @InvocableVariable public String serviceTerritoryName;
    }
    @InvocableMethod(label='Handle STM Operations')
    public static void handleNewSTMOperation(List<FlowInputs> flowInputRecords){
        try {
            system.debug('flowInputRecords ::'+flowInputRecords);
            Map<String,List<String>> serTerNamVsUsrIdListForDelMap = new Map<String,List<String>>();
            Set<String> userIdForRemoval = new Set<String>();
            Set<String> serviceTerritoryNames = new Set<String>();
            Map<String,List<String>> serTerNamVsUsrIdListForCreateMap = new Map<String,List<String>>();
            for(FlowInputs flowInpRec : flowInputRecords){
                if(String.IsNotBlank(flowInpRec.operationType) && String.IsNotBlank(flowInpRec.userId) && String.IsNotBlank(flowInpRec.serviceTerritoryName)){
                    serviceTerritoryNames.add(flowInpRec.serviceTerritoryName);
                    if(flowInpRec.operationType.equalsIgnoreCase('Create')){
                        serTerNamVsUsrIdListForCreateMap = filterUserwithSerTerName(serTerNamVsUsrIdListForCreateMap,flowInpRec);
                    }
                    else {
                        userIdForRemoval.add(flowInpRec.userId);
                        serTerNamVsUsrIdListForDelMap = filterUserwithSerTerName(serTerNamVsUsrIdListForDelMap,flowInpRec);
                    }
                }
            }
            
            Set<Id> grpIds = new Set<Id>();
            List<GroupMember> grpMemberInsertList = new List<GroupMember>();
            for (Group grp : [SELECT id, Name FROM Group where Name IN :serviceTerritoryNames]){
                if(serTerNamVsUsrIdListForCreateMap.containsKey(grp.Name)){
                    for(String userIdWithOpeType : serTerNamVsUsrIdListForCreateMap.get(grp.Name)){
                        grpMemberInsertList.add(new GroupMember(GroupId = grp.Id , UserOrGroupId = userIdWithOpeType));
                    }
                }
                else if(serTerNamVsUsrIdListForDelMap.containsKey(grp.Name)){
                    grpIds.add(grp.Id);
                }
            }
            
            List<Id> grpMemberRemovalIds = new List<Id>();
            for (GroupMember grpMemRec : [Select Id,Group.Name,UserOrGroupId from GroupMember Where UserOrGroupId IN :userIdForRemoval AND GroupId IN :grpIds]) {
                if(serTerNamVsUsrIdListForDelMap.containsKey(grpMemRec?.Group?.Name) && serTerNamVsUsrIdListForDelMap.get(grpMemRec?.Group?.Name).contains(grpMemRec.UserOrGroupId)){
                    grpMemberRemovalIds.add(grpMemRec.Id);
                }
            }
            
            dmlOnGroupMember(grpMemberRemovalIds,JSON.serialize(grpMemberInsertList));
        } catch (Exception e) {
            system.debug('exception ::'+e);
        }
    }
    
    public static Map<String,List<String>> filterUserwithSerTerName(Map<String,List<String>> serTerNamVsUsrIdListMap,FlowInputs flowInpRec){
        if(!serTerNamVsUsrIdListMap.containskey(flowInpRec.serviceTerritoryName)){
            serTerNamVsUsrIdListMap.put(flowInpRec.serviceTerritoryName,new List<String>{flowInpRec.userId});
        }
        else{
            List<String> userIds = new List<String> {flowInpRec.userId};
                userIds.addAll(serTerNamVsUsrIdListMap.get(flowInpRec.serviceTerritoryName));
            serTerNamVsUsrIdListMap.put(flowInpRec.serviceTerritoryName,userIds);
        }
        return serTerNamVsUsrIdListMap;
    }
    
    @future
    public static void dmlOnGroupMember(List<Id> grpMemberRemovalIds, String grpMemberRecs){
        List<GroupMember> grpMemberInsertList = (List<GroupMember>) JSON.deserialize(grpMemberRecs, List<GroupMember>.class);
        Database.SaveResult[] saveResults= Database.insert(grpMemberInsertList,false);
        Database.DeleteResult[] deleteResults = Database.delete(grpMemberRemovalIds,false);
        system.debug('saveResults ::'+saveResults);
        system.debug('deleteResults ::'+deleteResults);
    }
}