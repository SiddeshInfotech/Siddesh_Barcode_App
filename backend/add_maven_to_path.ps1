$mavenPath = "D:\apache-maven-3.9.16\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)

# Check if the path is already added
if ($userPath -notlike "*$mavenPath*") {
    # Ensure there is a semicolon before appending if not empty
    if ($userPath -and $userPath -notmatch ";$") {
        $newPath = $userPath + ";" + $mavenPath
    } else {
        $newPath = $userPath + $mavenPath
    }

    # Set the updated Path variable for the User
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
    
    Write-Host "Successfully added $mavenPath to your User PATH environment variable." -ForegroundColor Green
    Write-Host "IMPORTANT: You must close this PowerShell window and open a new one for the changes to take effect." -ForegroundColor Yellow
} else {
    Write-Host "The path $mavenPath is already in your PATH." -ForegroundColor Cyan
}
