const util = require('util');
const exec = util.promisify(require('child_process').exec);
const params = process.argv.slice(2);
const username = params[0];

const DATA_FOLDER = "data/sample";
const APEX_SCRIPTS = `${DATA_FOLDER}/scripts/apex`;

async function importSampleData() {
    try {
        //remove existing data
        let removeData_script = `sfdx apex run -f ${APEX_SCRIPTS}/removeData.apex --target-org ${username}`;
        const removingData_process = await exec(removeData_script);
        console.log('Stdout', removingData_process);

        //disable Automation Processes
        let preimport_script = `sfdx apex:run -f ${APEX_SCRIPTS}/preImportProcesses.apex --target-org ${username}`;
        const preimport_process = await exec(preimport_script);
        console.log('Stdout', preimport_process);

        //create users
        let users_script = `sfdx apex:run -f ${APEX_SCRIPTS}/createUsers.apex --target-org ${username}`;
        const createUsers = await exec(users_script);
        console.log('Stdout', createUsers);

        //importing test data
        let sfdmu_import = `sfdx sfdmu:run --sourceusername csvfile --targetusername ${username}`;
        console.log('Importing data in progress...');
        const import_test_data = await exec(`cd ${DATA_FOLDER} && ${sfdmu_import}`);
        console.log('Stdout', import_test_data);

        //enable Automation Processes and activate contractsF
        let postimport_script = `sfdx apex:run -f ${APEX_SCRIPTS}/postImportProcesses.apex --target-org ${username}`;
        const postimport_process = await exec(postimport_script);
        console.log('Stdout', postimport_process);
        console.log('Importing data has been finished.');
    } catch (error) {
        console.log(error);
    }
}

importSampleData();
