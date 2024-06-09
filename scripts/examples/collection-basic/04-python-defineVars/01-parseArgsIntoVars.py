
import argparse


print("Parsing args inside python script...");

# parse command line arguments

parser = argparse.ArgumentParser()

parser.add_argument('--orgAlias', help='org alias')
parser.add_argument('--accessToken', help='access token')
parser.add_argument('--instanceUrl', help='instance url')
parser.add_argument('--apiVersion', help='api version')
parser.add_argument('--workingDir', help='working directory')

# parse known args and just collect unknown but without failing
args, unknown = parser.parse_known_args()

print("orgAlias=%s" % args.orgAlias)
print("instanceUrl=%s" % args.instanceUrl)
print("apiVersion=%s" % args.apiVersion)
print("workingDir=%s" % args.workingDir)


# return results by appending properties in predefined file

f = open(".return.properties", "a");

f.write("SF_SR_VAR_SCRIPT_LANGUAGE=Python\n");
f.write("SF_SR_VAR_ORG_ALIAS=%s\n" % args.orgAlias);
f.write("SF_SR_VAR_SF_INSTANCE_URL=%s\n" % args.instanceUrl);
f.write("SF_SR_VAR_SF_API_VERSION=%s\n" % args.apiVersion);
f.write(f"SF_SR_VAR_WORKING_DIR={args.workingDir}\n");

f.close();


