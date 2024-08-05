/**
* Description : Asset trigger. Executes under the context: After Update
* Author : Adtiya Kannaujia
* Version : 01
* Created Date : 02-08-2024
*/
trigger FSL_AssetTrigger on Asset (after update) {
    TriggerDispatcher.fsl_run(new FSL_AssetHandler(), Asset.getSObjectType().getDescribe().getName());
}