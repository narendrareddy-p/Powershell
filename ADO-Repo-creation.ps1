<# 
Run the following command and complete the browser authentication
az login
Set Execution Policy (One-time per session)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Run the script pass the below variables
.\ADO_git_repo.ps1 -PROJECT "<ProjectName>" -repository "<RepositoryName>"
A new Azure DevOps browser window will pop up Click InitializeAfter initialization, click OK to complete the action.
#>

# You should be logged in to Azure, please use 'az login' command.
# It is interactive command that will create PowerShell session for you.
# The following AZ commands will use authorisation of your account.

param (
    [string]$PROJECT = "Devops",
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$repository
)

# Prompt for the mandatory parameter if not provided
if (-not $repository) {
    $repository = Read-Host "Enter the repository name"
}

# Show the default value for PROJECT and allow the user to confirm or change it
$PROJECT = Read-Host "Enter the project name (default: $PROJECT)" -Default $PROJECT

Write-Output "Project: $PROJECT"
Write-Output "Repository: $repository"

$ErrorActionPreference = "Stop"

# Set your organization and project
$ORG_URL = "https://dev.azure.com/greatamri/ca-devops"
az devops configure --defaults organization=$ORG_URL project=$PROJECT

# Test result of setting
az devops configure --list

# Create repository
az repos create `
    --project $PROJECT `
    --name $repository `
    --open `
    --output table

$repositoryId = az repos list `
    --project $PROJECT `
    --query "[?name=='$repository'].id" `
    --output tsv

# Define the URL of the ADO page
$adoUrl = "$ORG_URL/$PROJECT/_git/$repository?path=%2F&version=GBmain&initialize=true"

# Open the web browser to the ADO page
Start-Process "msedge.exe" $adoUrl

# Display a message to the operator and wait for their confirmation
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "Please go to the ADO website and use the 'Initialize' button to initialize the Azure repository. Click OK once you have completed this action.",
    "Action Required"
)

Write-Output "Initialization confirmed. Continuing with the rest of the script..."

# Create branches
az repos ref create `
    --project $PROJECT `
    --name "refs/heads/develop" `
    --repository $repository `
    --object-id $(az repos ref list `
        --project $PROJECT `
        --repository $repository `
        --query "[?name=='refs/heads/main'].objectId" `
        --output tsv)

# Enable policy for pull requests and minimum two reviewers
az repos policy approver-count create `
    --project $PROJECT `
    --repository-id $repositoryId `
    --branch "refs/heads/main" `
    --minimum-approver-count 1 `
    --creator-vote-counts false `
    --allow-downvotes false `
    --reset-on-source-push true `
    --blocking true `
    --enabled true

# Check if repository has been created
az repos show `
    --project $PROJECT `
    --repository $repository `
    --output table
