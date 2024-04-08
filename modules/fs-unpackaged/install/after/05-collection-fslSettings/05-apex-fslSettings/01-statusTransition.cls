
FSL.GlobalAPIS.clearAllStatusTransitions();

FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Canceled');
FSL.GlobalAPIS.addStatusTransition('None', 'Scheduled');
FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Dispatched');
FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Enroute');
FSL.GlobalAPIS.addStatusTransition('Scheduled', 'None');
FSL.GlobalAPIS.addStatusTransition('Completed', 'Onsite');
FSL.GlobalAPIS.addStatusTransition('Enroute', 'Onsite');
FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Onsite');
FSL.GlobalAPIS.addStatusTransition('Completed', 'Enroute');
FSL.GlobalAPIS.addStatusTransition('Onsite', 'Completed');
FSL.GlobalAPIS.addStatusTransition('Onsite', 'Canceled');
FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Accepted');
FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Rejected');
FSL.GlobalAPIS.addStatusTransition('Accepted', 'Enroute');
FSL.GlobalAPIS.addStatusTransition('Accepted', 'Canceled');
FSL.GlobalAPIS.addStatusTransition('Onsite', 'Cannot Execute');
FSL.GlobalAPIS.addStatusTransition('Onsite', 'Cannot Complete');
FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Onsite');
FSL.GlobalAPIS.addStatusTransition('None', 'Canceled');
FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Canceled');

