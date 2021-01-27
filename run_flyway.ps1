param(
    [String] $DB_URL,
    [String] $DB_DBNAME,
    [String] $DB_USER,
    [String] $DB_PASSWORD,
    [String[]] $Operations,
    [String]$SourceBranch,
    [Boolean]$MIGRATION_EXECUTE,
    [String]$ScriptsPath,
    [String]$ignoreMissingMigrations,
    [String]$repository
)
function FinishWithSuccess {
    Write-Output "##vso[task.complete result=Succeeded;]DONE"
}
function FinishWithError {
    Write-Output "##vso[task.complete result=Failed;]DONE"
}
function PrintLog {
    param (
        [String]$Message,
        [ERROR_TYPE] $Type
    )
    Write-Output "##vso[task.logissue type=$Type;]$Message"
}
function DockerFlywayExecute {
    param (
        [String]$Operation
    )
    docker run --rm -v "$env:SYSTEM_DEFAULTWORKINGDIRECTORY/$($ScriptsPath):/flyway/sql" "flyway/flyway" "-url=jdbc:sqlserver://$DB_URL;databaseName=$DB_DBNAME" "-user=$DB_USER" "-password=$DB_PASSWORD" "-baselineOnMigrate=true" $Operation "-ignoreMissingMigrations=$ignoreMissingMigrations" 
}
function CheckErrorExistance {
    param (
        [System.Array]$OutputFlyway
    )
    $MinimalAcceptedErrors = 0;
    $OutputFlywayErrors = $OutputFlyway -match "ERROR";
    return $OutputFlywayErrors.Length -gt $MinimalAcceptedErrors    
}
enum ERROR_TYPE {
    warning
    error
}
try {
    if(-not ($MIGRATION_EXECUTE -eq $true)){
        Write-Output "Flyway setted to do not execute"
        PrintLog "Flyway setted to do not execute" -Type warning
        FinishWithSuccess
    }
    # Change to $(Release.Artifacts._Online_QA.SourceBranchName) after tests
    try {
        $SourceBranchWithoutPrefix = $SourceBranch.Replace("refs/heads/","");
        Write-Output "Checkout to $SourceBranchWithoutPrefix branch"; 
        Set-Location -Verbose "$env:SYSTEM_DEFAULTWORKINGDIRECTORY/_$($repository)";
        git checkout $SourceBranchWithoutPrefix;
        # Remove, just to print .sql files 
        # gci "$env:SYSTEM_DEFAULTWORKINGDIRECTORY/_GEOTEC/20 - Fontes/Workspace/Geotec/src/main/resources/db/migration/"
    }
    catch {
        throw "Error while checkout to branch $SourceBranchWithoutPrefix"
    }
    try {
        Write-Output "System default working directory + path: $env:SYSTEM_DEFAULTWORKINGDIRECTORY/$($ScriptsPath):/flyway/sql";
        Write-Output "Script Path: $($ScriptsPath)";
        [Int16]$ZeroOperationsSpecified = 0;
        if($Operations.Length -le $ZeroOperationsSpecified ){ throw "Has no operations (migrate, info, repair) specified" }
        foreach ($op in $Operations) {
            Write-Output "Running flyway $op"
            if($op -eq "migrate") { 
                $Output = DockerFlywayExecute $op;
                $Result = CheckErrorExistance $Output;
                if($Result) {
                    throw "$Output" 
                } else {
                    Write-Output $Output
                }
            } else {
                DockerFlywayExecute $op 
            }
        }
    }
    catch {
        throw "Error while execute script: $_"
    }
}
catch {
    PrintLog "Error while running flyway $_" -Type error
    FinishWithError
}