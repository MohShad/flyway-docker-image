var tl = require('azure-pipelines-task-lib/task');
var spawn = require("child_process").spawn, child;

const dataBaseUrl = tl.getInput('dataBaseUrl', true);
const dataBaseName = tl.getInput('dataBaseName', true);
const dataBaseUsername = tl.getInput('dataBaseUsername', true);
const dataBasePassword = tl.getInput('dataBasePassword', true);
const operations = tl.getInput('operations', true);
const sourceBranch = tl.getInput('sourceBranch', true);
const migrationExecute = tl.getInput('migrationExecute', true);
const scriptPath = tl.getInput('scriptPath', true);
const ignoreMissingMigrations = tl.getInput('ignoreMissingMigrations', true);

child = spawn("powershell.exe", [
    `.\\run_flyway.ps1 
    -DB_URL ${dataBaseUrl} 
    -DB_DBNAME ${dataBaseName} 
    -DB_USER ${dataBaseUsername} 
    -DB_PASSWORD ${dataBasePassword} 
    -Operations ${operations} 
    -SourceBranch ${sourceBranch} 
    -MIGRATION_EXECUTE ${migrationExecute} 
    -ScriptsPath ${scriptPath} 
    -ignoreMissingMigrations ${ignoreMissingMigrations}`
]);

child.stdout.on("data", function (data) {
    console.log("Powershell Data: " + data);
});
child.stderr.on("data", function (data) {
    console.log("Powershell Errors: " + data);
});
child.on("exit", function () {
    console.log("Powershell Script finished");
});
child.stdin.end(); //end input