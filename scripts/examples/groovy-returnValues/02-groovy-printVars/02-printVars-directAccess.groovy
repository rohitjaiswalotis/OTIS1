
println("Printing variables defined on previous steps inside groovy script (direct access)....");

def env = System.getenv();

println("SF_SR_VAR_SCRIPT_LANGUAGE = ${env['SF_SR_VAR_SCRIPT_LANGUAGE']}");
println("SF_SR_VAR_ORG_ALIAS = ${env['SF_SR_VAR_ORG_ALIAS']}");
println("SF_SR_VAR_SF_INSTANCE_URL = ${env['SF_SR_VAR_SF_INSTANCE_URL']}");
println("SF_SR_VAR_SF_API_VERSION = ${env['SF_SR_VAR_SF_API_VERSION']}");
println("SF_SR_VAR_WORKING_DIR = ${env['SF_SR_VAR_WORKING_DIR']}");


def returnFile = new File('.return.properties');

returnFile.withWriterAppend { fileWriter ->			
	
	fileWriter.println("SF_SR_VAR_PROP_FROM_ANOTHER_STEP=TestPropValue");
	
}
