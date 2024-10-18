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
	"$Date`t$Message" | Out-File $LogFile -Append

	<#
        .SYNOPSIS
        Add Message to LogFile.

        .DESCRIPTION
        Adds timestamp and Message to LogFile.
    #>
}

$Applications = Get-ChildItem -Path C:\Temp\prep\apps | Where-Object{$_.Name -match 'msi|exe'}
$InstallInstructions = "C:\Temp\prep\apps\Setup.csv"

if($ApplicationInstall){
    # Documents the application install start time.
    "[AppSetup Start]" | Add-LogMessage $LogFile
    
    # Gets the log file contents.
    $Logs = Get-Content -Path $LogFile

    # Recovers application installation commands.
    $Commands = Import-Csv -Path $InstallInstructions

    foreach($Application in $Applications){        
        # Recovers the installation structions from the setup CSV
        # if they exist.
        if($Commands.Application -contains $Application.Name){
            $Installer = $Commands[$Commands.Application.IndexOf($Application.Name)]
        }else{
            $Installer = $null
        }
        
        if(-not $Installer){
            # Checks if the installation of the application was already attempted.
            $LogCheck = $Logs | Where-Object{$_ -like "*Installing*$($Application.Name)*"}
            if($LogCheck){
                Continue
            }
            # If no instructions are found, runs the installer manually.
            "Installing (Manual) $($Application.Name)" | Add-LogMessage $LogFile
            Start-Process -FilePath $Application.FullName -Verb RunAs -Wait
        }else{
            # Checks if the application was already installed using the install test string.
            if(Test-Path -Path $Installer.InstallTest){
                Continue
            }else{
                "Installing (Automatic) $($Application.Name) $($Installer.Command)" | Add-LogMessage $LogFile
                Start-Process -FilePath $Application.FullName -ArgumentList $Installer.Command -Verb RunAs -Wait -OutVariable InstallResult
                if($InstallResult){
                    $InstallResult | ForEach-Object("`t$_" | Add-LogMessage $LogFile)
                }
            }
        }
    }

    # Documents the application install end time.
    "[AppSetup End]" | Add-LogMessage $LogFile
}