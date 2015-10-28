#*******Verify these Parameters******
$locationOfSourceFiles = "C:\_builds\4.1.2"
$fileToReadServices =  "C:\_Servers\TestIPs.txt"
$fileToReadLocations =  "C:\_Servers\CopyLocations.txt"
#*****Should not need to adjust anything below here *****

#****************************Functions*******************************************
function FuncStopService([string]$ServiceName, [string] $computers)
{
    Write-host "Checking" $computers $ServiceName
    $arrService = Get-Service -ComputerName $computers -Name $ServiceName
    if ($arrService.Status -ne "Stopped")
    {
        Write-Host "Stopping" $ServiceName "service"
        "---------------------------------------"    
        ($arrService).Stop()
         $arrService.WaitForStatus('Stopped',(new-timespan -seconds 20))
        " Service is now stopped"                 
        "---------------------------------------" 
    }
    else
    {
        "---------------------------------------"
        Write-Host "$ServiceName service is already stopped"
        "---------------------------------------"
    }
 }

 function FuncStartService ([string]$ServiceName, [string]$computers)
 {
    Write-host "Checking" $computers $ServiceName
    $arrService = Get-Service -ComputerName $computers -Name $ServiceName
    if ($arrService.Status -ne "Running")
    {
        Write-Host "Starting" $ServiceName "service"
        "---------------------------------------"             
        ($arrService).Start() 
        $arrService.WaitForStatus('Running',(new-timespan -seconds 20)) 
        " Service is now started"               
        "---------------------------------------" 
    } 
    else
    { 
        "---------------------------------------"
        Write-Host "$ServiceName service is already running"
        "---------------------------------------"
    }
 }

 function GetServiceStatus
 {
    $csvServices=Import-Csv $fileToReadServices

    foreach ($lineService in $csvServices) {
    Get-Service -ComputerName $lineService.Computer -Name $lineService.ServiceName
    }
 }

function Check-Dir-Exists ([string] $computers)
{
    if(!(Test-Path -Path $computers))
    {
        write-host $computers "not found." -foregroundcolor red;        
        write-host "Location parameters are incorrect .... exiting. No changes were made. Please correct and rerun" -foregroundcolor red
        break       
    } 
    else 
    {
        write-host $computers "found." -foregroundcolor green
    }
}

function CreatePathIfDoesntExist ([string] $path)
{
    if(!(Test-Path -Path $path))
	{
	   new-item -path $path -type directory -force
       write-host $path " was created." -foregroundcolor green;
    } 
	else 
	{
		write-host $path "found." -foregroundcolor green
	}
}

#**********************************Code************************************

$ErrorActionPreference = "Stop"
Check-Dir-Exists($fileToReadServices)
Check-Dir-Exists($fileToReadLocations)
$csvServices=Import-Csv $fileToReadServices

foreach ($lineService in $csvServices) {
$stopService = FuncStopService $lineService.ServiceName $lineService.Computer}

$csvLocations = Import-Csv $fileToReadLocations
foreach ($lineLocations in $csvLocations) 
{
    if ($lineLocations.Job -ne "Deploy"){Check-Dir-Exists($lineLocations.PathToBinaries)} else {CreatePathIfDoesntExist $lineLocations.PathToBinaries}

    $job = $lineLocations.Job
    switch ($job)
    {     
        {$job -eq "Deploy"} {remove-item ($lineLocations.PathToBinaries+'\*') -Recurse -force}      
        {$job -eq "Deploy"} {copy-item $locationOfSourceFiles\Scripts\* $lineLocations.PathToBinaries -recurse -ErrorVariable capturedErrors -ErrorAction SilentlyContinue}
        {$job -eq "Deploy"} {copy-item $locationOfSourceFiles\Configs\* $lineLocations.PathToBinaries -recurse -ErrorVariable capturedErrors -ErrorAction SilentlyContinue}
        {$job -eq "Web"} {remove-item ($lineLocations.PathToBinaries+'\*') -Recurse -Exclude *.config -force}    
        {$job -eq "Web"} {copy-item $locationOfSourceFiles\Web\* $lineLocations.PathToBinaries -recurse -ErrorVariable capturedErrors -ErrorAction SilentlyContinue}
        {$job -eq "WHS"} {remove-item ($lineLocations.PathToBinaries+'\*') -Recurse -Exclude *.config -force}     
        {$job -eq "WHS"} {copy-item $locationOfSourceFiles\WHS\* $lineLocations.PathToBinaries -recurse -ErrorVariable capturedErrors -ErrorAction SilentlyContinue}
        {$job -eq "Delegator"} {remove-item ($lineLocations.PathToBinaries+'\*') -Recurse -Exclude *.config -force}   
        {$job -eq "Delegator"} {copy-item $locationOfSourceFiles\Delegator\* $lineLocations.PathToBinaries -recurse -ErrorVariable capturedErrors -ErrorAction SilentlyContinue}
    }
}

foreach ($lineService in $csvServices) {
$startService = FuncStartService $lineService.ServiceName $lineService.Computer}
GetServiceStatus

Write-Host "Process is complete." -foregroundcolor green