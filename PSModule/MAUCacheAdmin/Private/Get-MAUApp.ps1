function Get-MAUApp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $AppID,
        [Parameter(Mandatory=$true)]
        [string]
        $AppName,
        [Parameter(Mandatory=$true)]
        [Uri]
        $ChannelURI,
        [Parameter(Mandatory=$true)]
        [System.Net.Http.HttpClient]
        $HttpClient
    )

    $logPrefix = "$($MyInvocation.MyCommand):"
    Write-Verbose "$logPrefix Processing AppID = $AppID, AppName = $AppName, ChannelURI = $ChannelURI"

    # Define Collateral Object
    $app = [PSCustomObject]@{
        AppID = $AppID
        AppName = $AppName
        VersionInfo = $null
        CollateralURIs = [PSCustomObject]@{
            AppXML = [Uri]::new($ChannelURI, "$AppID.xml")
            CAT = [Uri]::new($ChannelURI, "$AppID.cat")
            ChkXml = [Uri]::new($ChannelURI, "$AppID-chk.xml")
            HistoryXML = [Uri]::new($ChannelURI, "$AppID-history.xml")
        }
        Packages = $null
        HistoricPackages = @{}
    }

    # Process App XML
    Write-Verbose "$logPrefix Getting App Packages"
    [System.Collections.Specialized.OrderedDictionary[]]$appPackageDicts = Get-PlistObjectFromURI -URI $app.CollateralURIs.AppXML -HttpClient $HttpClient
    if ($null -eq $appPackageDicts) {
        Write-Verbose "$logPrefix No object returned from Get-PlistObjectFromURI!"
        throw "Failed to process $($app.CollateralURIs.AppXML)"
    }
    $app.Packages = @(ConvertFrom-AppPackageDictionary -AppPackageDictionaries $appPackageDicts)

    # Process Version Check XML
    Write-Verbose "$logPrefix Getting App Version Info"
    try {
        $versionObj = [PSCustomObject](Get-PlistObjectFromURI -URI $app.CollateralURIs.ChkXml -HttpClient $HttpClient)
        $app.VersionInfo = [PSCustomObject]@{
            Version = $versionObj.'Update Version'
            Date = Get-Date $versionObj.Date
            Type = $versionObj.Type
        }
    }
    catch [System.Net.Http.HttpRequestException] {
        $statusCode = $_.Exception.StatusCode

        # Rethrow exception if its not a 404
        if ($statusCode -ne [System.Net.HttpStatusCode]::NotFound) {
            throw
        }

        # Rethrow if we don't have a single app to use as version/data pont of truth
        if ($app.Packages.Count -ne 1) {
            throw
        }
        
        # Use data from the App XML
        $app.VersionInfo = [PSCustomObject]@{
            Version = $app.Packages.'Update Version'
            Date = $app.Packages.Date
            Type = $app.Packages.Type
        }
    }

    # Fix unknown versions
    if ($app.VersionInfo.Version -eq "99999") {
        $verFromPkg = @($app.Packages.'Update Version')[0]

        $app.VersionInfo.Version = if ($null -eq $verFromPkg) {"Legacy"} else {$verFromPkg}
    }

    # Process App History XML
    Write-Verbose "$logPrefix Getting App History Packages"
    [string[]]$historicAppVersions = Get-PlistObjectFromURI -URI $app.CollateralURIs.HistoryXML -HttpClient $HttpClient -Optional
    if ($null -eq $historicAppVersions) {
        # Leave HistoricPackages empty ( -history.xml files are optional and only on certain apps )
        Write-Verbose "$logPrefix No App history XML found"
        return $app
    }
    Write-Verbose "$logPrefix Found $($historicAppVersions.Count) historic versions ($($historicAppVersions -join ", "))"
    $historicAppVersions | ForEach-Object {
        [System.Collections.Specialized.OrderedDictionary[]]$historyAppPackageDicts = Get-PlistObjectFromURI -URI ([Uri]::new($ChannelURI, "$($AppID)_$_.xml")) -HttpClient $HttpClient
        $historyAppPackageObjs = @(ConvertFrom-AppPackageDictionary -AppPackageDictionaries $historyAppPackageDicts)
        $app.HistoricPackages[$_] = $historyAppPackageObjs
    }

    return $app
}