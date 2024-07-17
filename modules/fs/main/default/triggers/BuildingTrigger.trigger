trigger BuildingTrigger on Location (before insert, before update, after update ,after insert, after delete){
      	TriggerDispatcher.run(new BuildingTriggerHandler(), Schema.Location.getSObjectType().getDescribe().getName());  
}