
/*
// example snippet re how to schedule job
// schedule job to send reminders about holiday/overtime coverages via email notifications
scheduleIfNotExistWithSuchNameOrClass(
	'Route Coverages Email Reminder',
	'0 0 19 * * ? *', // run every day at 7 PM
	'ShiftCoverageEmailReminderBatch'
);
*/



public static Boolean scheduleIfNotExistWithSuchName(String jobName, String cronExpression, String className) {
	return scheduleIfNotExistWithSuchName(jobName, cronExpression, className, null);
}


public static Boolean scheduleIfNotExistWithSuchName(String jobName, String cronExpression, String className, String namespace) {
	
	if (isCronJobScheduledWithSuchName(jobName)) {
		return false;
	}
	
	return scheduleJob(jobName, cronExpression, className, namespace);
	
}



public static Boolean scheduleIfNotExistWithSuchClass(String jobName, String cronExpression, String className) {
	return scheduleIfNotExistWithSuchClass(jobName, cronExpression, className, null);
}


public static Boolean scheduleIfNotExistWithSuchClass(String jobName, String cronExpression, String className, String namespace) {
	
	if (isCronJobScheduledWithSuchClass(className, namespace)) {
		return false;
	}
	
	return scheduleJob(jobName, cronExpression, className, namespace);
	
}



public static Boolean scheduleIfNotExistWithSuchNameOrClass(String jobName, String cronExpression, String className) {
	return scheduleIfNotExistWithSuchNameOrClass(jobName, cronExpression, className, null);
}


public static Boolean scheduleIfNotExistWithSuchNameOrClass(String jobName, String cronExpression, String className, String namespace) {
	
	if (isCronJobScheduledWithSuchNameOrClass(jobName, className, namespace)) {
		return false;
	}
	
	return scheduleJob(jobName, cronExpression, className, namespace);
	
}



public static Boolean scheduleJob(String jobName, String cronExpression, String className, String namespace) {
	
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



public static Boolean isCronJobScheduledWithSuchName(String jobName) {
	
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
				)
			LIMIT 1
		]
		.isEmpty()
	;
	
}



public static Boolean isCronJobScheduledWithSuchClass(String className, String namespace) {
	
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



public static Boolean isCronJobScheduledWithSuchNameOrClass(String jobName, String className, String namespace) {
	
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


