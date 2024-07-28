
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
FSL.GlobalAPIS.addStatusTransition('Onsite', 'Cannot Complete');
FSL.GlobalAPIS.addStatusTransition('Dispatched', 'Onsite');
FSL.GlobalAPIS.addStatusTransition('None', 'Canceled');
FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Canceled');
FSL.GlobalAPIS.addStatusTransition('Dispatched', 'None');
FSL.GlobalAPIS.addStatusTransition('Accepted', 'None');
FSL.GlobalAPIS.addStatusTransition('Accepted', 'Dispatched');
FSL.GlobalAPIS.addStatusTransition('Rejected', 'None');
FSL.GlobalAPIS.addStatusTransition('Rejected', 'Dispatched');
FSL.GlobalAPIS.addStatusTransition('Enroute', 'None');
FSL.GlobalAPIS.addStatusTransition('Enroute', 'Dispatched');
FSL.GlobalAPIS.addStatusTransition('Onsite', 'None');
FSL.GlobalAPIS.addStatusTransition('Onsite', 'Dispatched');

