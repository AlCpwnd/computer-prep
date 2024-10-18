<#
    Manages the application installation and removal.
    - Installs the applications contained in the C:\Temp\prep\apps folder.
#>

param(
    [Parameter(Mandatory)][String]$LogFile
)

function Add-LogMessage{
	param(
		[Parameter(MandaTory, Position=0)][String]$LogFile,
		[Parameter(Mandatory, ValueFromPipeline)][String]$Message
	)
	$Date = Get-Date -Format HH:MM:ss
	"$Date`t$Message" | Out-File $LogFile -Append -Encoding ascii
    Write-Verbose $Message

	<#
        .SYNOPSIS
        Add Message to LogFile.

        .DESCRIPTION
        Adds timestamp and Message to LogFile.
    #>
}

$AppFolder = "C:\Temp\prep\apps"

$Applications = Get-ChildItem -Path $AppFolder | Where-Object{$_.Name -match 'msi|exe'}
$InstallInstructions = "$AppFolder\Setup.csv"

if($Applications){
    # Moves the script run location to the folder.
    Push-Location -Path $AppFolder

    # Documents the application install start time.
    "[AppSetup Start]" | Add-LogMessage $LogFile
    
    # Gets the log file contents.
    $Logs = Get-Content -Path $LogFile

    # Recovers application installation commands.
    $Commands = Import-Csv -Path $InstallInstructions

    foreach($App in $Applications){       
        # Adds undocumented apps to the Commands variable. 
        if($Commands.Application -notcontains $App.Name){
            $Commands += @{
                Application = $App.Name
                Command = ''
                InstallTest = ''
            }
        }
    }

    foreach($App in $Commands){
        # Checks if application is installed. Depending on if
        # a test is given or not.
        if($App.InstallTest){            
            if(Test-Path -Path $App.InstallTest){
                Continue
            }
        }else{
            $LogCheck = $Logs | Where-Object{$_ -like "*Installing*$($App.Name)*"}
            if($LogCheck){
                Continue
            }
        }

        # Install the application depending if instructions are
        # given or not.
        if($App.Command){
            "Installing (Automatic) $($App.Name) $($App.Command)" | Add-LogMessage $LogFile
            Start-Process -FilePath $App.FullName -ArgumentList $App.Command -Verb RunAs -Wait -OutVariable InstallResult
            if($InstallResult){
                $InstallResult | ForEach-Object("`t$_" | Add-LogMessage $LogFile)
            }
        }else{
            "Installing (Manual) $($App.Name)" | Add-LogMessage $LogFile
            Start-Process -FilePath $App.FullName -Verb RunAs -Wait
        }
    }

    # Documents the application install end time.
    "[AppSetup End]" | Add-LogMessage $LogFile
}