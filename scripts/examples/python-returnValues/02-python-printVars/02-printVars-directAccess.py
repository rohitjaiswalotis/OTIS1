
import os

print("Printing variables defined on previous steps inside python script (direct access)....");

print("SF_SR_VAR_SCRIPT_LANGUAGE = %s\n" % os.environ.get('SF_SR_VAR_SCRIPT_LANGUAGE'));
print("SF_SR_VAR_ORG_ALIAS = %s\n" % os.environ.get('SF_SR_VAR_ORG_ALIAS'));
print("SF_SR_VAR_SF_INSTANCE_URL = %s\n" % os.environ.get('SF_SR_VAR_SF_INSTANCE_URL'));
print("SF_SR_VAR_SF_API_VERSION = %s\n" % os.environ.get('SF_SR_VAR_SF_API_VERSION'));
print(f"SF_SR_VAR_WORKING_DIR = {os.environ.get('SF_SR_VAR_WORKING_DIR')}\n");


# return results by appending properties in predefined file

f = open(".return.properties", "a");

f.write("SF_SR_VAR_PROP_FROM_ANOTHER_STEP=TestPropValue\n");

f.close();

