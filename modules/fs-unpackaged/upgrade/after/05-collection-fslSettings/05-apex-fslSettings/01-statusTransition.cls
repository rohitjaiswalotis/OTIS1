
List<FSL.StatusTransition> updatedStatusTransitions = new List<FSL.StatusTransition>();


// filter out some status transitions to be removed
for (FSL.StatusTransition currentStatusTransition : FSL.GlobalAPIS.getAllStatusTransitions()) {
	
	if (
		currentStatusTransition.fromStatus?.equalsIgnoreCase('Onsite')
		&&
		currentStatusTransition.toStatus?.equalsIgnoreCase('Canceled')
	) {
		continue;
	}
	
	updatedStatusTransitions.add(
		currentStatusTransition
	);
	
}


// remove all status transitions
FSL.GlobalAPIS.clearAllStatusTransitions();


// put back filtered status transitions
for (FSL.StatusTransition updatedStatusTransition : updatedStatusTransitions) {
	
	FSL.GlobalAPIS.addStatusTransition(
		updatedStatusTransition
	);
	
}


// add new status transitions on top existent once
try {
	FSL.GlobalAPIS.addStatusTransition('Cannot Complete', 'Canceled');
} catch (Exception exp) {
    // suppress errors deliberately in case of such status transition already exists
}

