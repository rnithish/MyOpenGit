﻿<##################################################################################################

    Description
    ===========

	- This script does the following - 
		- installs chocolatey
		- installs specified chocolatey packages

	- This script generates logs in the following folder - 
		- %ALLUSERSPROFILE%\ChocolateyPackageInstaller-{TimeStamp}\Logs folder.


    Usage examples
    ==============
    
    Powershell -executionpolicy bypass -file ChocolateyPackageInstaller.ps1


    Pre-Requisites
    ==============

    - Ensure that the powershell execution policy is set to unrestricted (@TODO).


    Known issues / Caveats
    ======================
    
    - No known issues.


    Coming soon / planned work
    ==========================

    - N/A.    

##################################################################################################>

#
# Optional arguments to this script file.
#

Param(
    # comma or semicolon separated list of chocolatey packages.
    [ValidateNotNullOrEmpty()]
    [string]
    $RawPackagesList
)

##################################################################################################

#
# Powershell Configurations
#

# Note: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.  
$ErrorActionPreference = "stop"

# Ensure that current process can run scripts. 
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force 

###################################################################################################

#
# Custom Configurations
#

$ChocolateyPackageInstallerFolder = Join-Path $env:ALLUSERSPROFILE -ChildPath $("ChocolateyPackageInstaller-" + [System.DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss"))

# Location of the log files
$ScriptLog = Join-Path -Path $ChocolateyPackageInstallerFolder -ChildPath "ChocolateyPackageInstaller.log"
$ChocolateyInstallLog = Join-Path -Path $ChocolateyPackageInstallerFolder -ChildPath "ChocolateyInstall.log"

##################################################################################################

# 
# Description:
#  - Displays the script argument values (default or user-supplied).
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - Please ensure that the Initialize() method has been called at least once before this 
#    method. Else this method can only write to console and not to log files. 
#

function DisplayArgValues
{
    WriteLog "========== Configuration =========="
    WriteLog $("RawPackagesList : " + $RawPackagesList)
    WriteLog "========== Configuration =========="
}

##################################################################################################

# 
# Description:
#  - Creates the folder structure which'll be used for dumping logs generated by this script and
#    the logon task.
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function InitializeFolders
{
    if ($false -eq (Test-Path -Path $ChocolateyPackageInstallerFolder))
    {
        New-Item -Path $ChocolateyPackageInstallerFolder -ItemType directory | Out-Null
    }
}

##################################################################################################

# 
# Description:
#  - Writes specified string to the console as well as to the script log (indicated by $ScriptLog).
#
# Parameters:
#  - $message: The string to write.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function WriteLog
{
    Param(
        <# Can be null or empty #> $message
    )

    $timestampedMessage = $("[" + [System.DateTime]::Now + "] " + $message) | % {  
        Write-Host -Object $_
        Out-File -InputObject $_ -FilePath $ScriptLog -Append
    }
}

##################################################################################################

# 
# Description:
#  - Installs the chocolatey package manager.
#
# Parameters:
#  - N/A.
#
# Return:
#  - If installation is successful, then nothing is returned.
#  - Else a detailed terminating error is thrown.
#
# Notes:
#  - @TODO: Write to $chocolateyInstallLog log file.
#  - @TODO: Currently no errors are being written to the log file ($chocolateyInstallLog). This needs to be fixed.
#

function InstallChocolatey
{
    Param(
        [ValidateNotNullOrEmpty()] $chocolateyInstallLog
    )

    WriteLog "Installing Chocolatey..."

    Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) | Out-Null

    WriteLog "Success."
}

##################################################################################################

#
# Description:
#  - Installs the specified chocolatet packages on the machine.
#
# Parameters:
#  - N/A.
#
# Return:
#  - N/A.
#
# Notes:
#  - N/A.
#

function InstallPackages
{
    Param(
        [ValidateNotNullOrEmpty()][string] $packagesList
    )

    $Separator = @(";",",")
    $SplitOption = [System.StringSplitOptions]::RemoveEmptyEntries
    $packages = $packagesList.Trim().Split($Separator, $SplitOption)

    if (0 -eq $packages.Count)
    {
        WriteLog $("No packages were specified. Exiting...")
        return        
    }

    foreach ($package in $packages)
    {
        WriteLog $("Installing package: " + $package)

        # install git via chocolatey
        choco install $package --force --yes --acceptlicense --verbose --allow-empty-checksums | Out-Null 

        if ($? -eq $false)
        {
            $errMsg = $("Error! Installation failed. Please see the chocolatey logs in %ALLUSERSPROFILE%\chocolatey\logs folder for details.")
            WriteLog $errMsg
            Write-Error $errMsg 
        }
    
        WriteLog "Success."        
    }
}

##################################################################################################

#
# 
#

try
{
    #
    InitializeFolders

    #
    DisplayArgValues
    
    # install the chocolatey package manager
    InstallChocolatey -chocolateyInstallLog $ChocolateyInstallLog

    # install the specified packages
    InstallPackages -packagesList $RawPackagesList
}
catch
{
    if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message))
    {
        $errMsg = $Error[0].Exception.Message
        WriteLog $errMsg
        Write-Host $errMsg
    }

    # Important note: Throwing a terminating error (using $ErrorActionPreference = "stop") still returns exit 
    # code zero from the powershell script. The workaround is to use try/catch blocks and return a non-zero 
    # exit code from the catch block. 
    exit -1
}