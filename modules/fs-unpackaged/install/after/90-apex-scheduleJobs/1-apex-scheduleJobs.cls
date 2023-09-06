
/*
// example snippet re how to schedule job
// schedule job to send reminders about holiday/overtime coverages via email notifications
scheduleIfNotExist(
	'Route Coverages Email Reminder',
	'0 0 19 * * ? *', // run every day at 7 PM
	'ShiftCoverageEmailReminderBatch'
);
*/


public static Boolean scheduleIfNotExist(String jobName, String cronExpression, String className) {
	return scheduleIfNotExist(jobName, cronExpression, className, null);
}


public static Boolean scheduleIfNotExist(String jobName, String cronExpression, String className, String namespace) {
	
	if (isCronJobScheduled(jobName, className, namespace)) {
		return false;
	}
	
	try {
		
		System.schedule(
			jobName,
			cronExpression,
			(Schedulable)
			Type.forName(
				namespace, 
				className
			).newInstance()
		);
		
		return true;
		
	} catch(Exception exp) {
		
		return false;
		
	}
	
}


public static Boolean isCronJobScheduled(String jobName, String className, String namespace) {
	
	return
		!
		[
			SELECT
				Id
			FROM
				AsyncApexJob
			WHERE
				CronTrigger.CronJobDetail.JobType = '7'
				AND
				(
					CronTrigger.CronJobDetail.Name = :jobName
					OR
					(
						ApexClass.Name = :className
						AND
						ApexClass.NamespacePrefix = :namespace
					)
				)
			LIMIT 1
		]
		.isEmpty()
	;
	
}

