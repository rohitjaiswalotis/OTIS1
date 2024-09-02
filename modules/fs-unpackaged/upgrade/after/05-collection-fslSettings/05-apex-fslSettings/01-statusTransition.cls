
Map<String, FSL.StatusTransition> transitionsToRemoveRegistry = 
	indexTransitionsByKey(
		new List<FSL.StatusTransition> {
			new FSL.StatusTransition(
				'Onsite',
				'Canceled'
			),
			new FSL.StatusTransition(
				'Enroute',
				'Dispatched'
			),
			new FSL.StatusTransition(
				'Onsite',
				'Dispatched'
			)
		}
	)
;

Map<String, FSL.StatusTransition> transitionsToAddRegistry = 
	indexTransitionsByKey(
		new List<FSL.StatusTransition> {
			new FSL.StatusTransition(
				'Cannot Complete',
				'Canceled'
			),
			new FSL.StatusTransition(
				'Enroute',
				'Cannot Complete'
			)
		}
	)
;


Map<String, FSL.StatusTransition> originalTransitionsRegistry = 
	indexTransitionsByKey(
		FSL.GlobalAPIS.getAllStatusTransitions()
	)
;


// filter out some status transitions to be removed
Map<String, FSL.StatusTransition> transitionsAfterRemovalRegistry = new Map<String, FSL.StatusTransition>(); {
	
	for (FSL.StatusTransition currentStatusTransition : originalTransitionsRegistry.values()) {
		
		String key = generateTransitionKey(currentStatusTransition);
		
		if (transitionsToRemoveRegistry.containsKey(key)) {
			continue;
		}
		
		transitionsAfterRemovalRegistry.put(
			key,
			currentStatusTransition
		);
		
	}
	
}


// removal is required
if (originalTransitionsRegistry.size() > transitionsAfterRemovalRegistry.size()) {
	
	// remove all status transitions
	FSL.GlobalAPIS.clearAllStatusTransitions();
	
	
	// put back filtered status transitions after global cleanup
	for (FSL.StatusTransition transitionAfterRemoval : transitionsAfterRemovalRegistry.values()) {
		
		FSL.GlobalAPIS.addStatusTransition(
			transitionAfterRemoval
		);
		
	}
	
}


// add new status transitions if not available already
for (FSL.StatusTransition transitionToAdd : transitionsToAddRegistry.values()) {
	
	String key = generateTransitionKey(transitionToAdd);
	
	if (transitionsAfterRemovalRegistry.containsKey(key)) {
		continue;
	}
	
	FSL.GlobalAPIS.addStatusTransition(
		transitionToAdd.fromStatus, 
		transitionToAdd.toStatus
	);
	
}



private static Map<String, FSL.StatusTransition> indexTransitionsByKey(List<FSL.StatusTransition> transitions) {
	
	Map<String, FSL.StatusTransition> transitionsRegistry = new Map<String, FSL.StatusTransition>();
	
	for (FSL.StatusTransition transition : transitions) {
		
		transitionsRegistry.put(
			generateTransitionKey(transition),
			transition
		);
		
	}
	
	
	return transitionsRegistry;
	
}



private static String generateTransitionKey(FSL.StatusTransition transition) {
	
	return
		transition.fromStatus?.toLowerCase() 
		+ 
		'$_###_$' 
		+ 
		transition.toStatus?.toLowerCase()
	;
	
}

