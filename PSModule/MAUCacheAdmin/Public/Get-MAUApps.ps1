function Get-MAUApps {
    [OutputType('System.Object[]')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Production", "Preview", "Beta")]
        [string]
        $Channel
    )

    # Set http client for the function
    $httpClient = [System.Net.Http.HttpClient]::new((Get-HttpClientHandler), $false)

    # Create URI builder and set the path based on the provided channel
    $mauCdnUriBuilder = [System.UriBuilder]::new("https://officecdnmac.microsoft.com")
    switch ($Channel) {
        "Production" { $mauCdnUriBuilder.Path = "/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/" }
        "Preview" { $mauCdnUriBuilder.Path = "/pr/1ac37578-5a24-40fb-892e-b89d85b6dfaa/MacAutoupdate/" }
        "Beta" {$mauCdnUriBuilder.Path = "/pr/4B2D7701-0A4F-49C8-B4CB-0C2D4043F51F/MacAutoupdate/" }
    }

    # Define the target apps
    $targetApps = @(
        #[PSCustomObject]@{AppID = "0409MSau03";     AppName = "MAU 3.x";                    Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409MSau04";     AppName = "MAU 4.x";                    Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409MSWD2019";   AppName = "Word 365/2021/2019";         Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409XCEL2019";   AppName = "Excel 365/2021/2019";        Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409PPT32019";   AppName = "PowerPoint 365/2021/2019";   Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409OPIM2019";   AppName = "Outlook 365/2021/2019";      Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409ONMC2019";   AppName = "OneNote 365/2021/2019";      Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409MSWD15";     AppName = "Word 2016";                  Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409XCEL15";     AppName = "Excel 2016";                 Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409PPT315";     AppName = "PowerPoint 2016";            Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409OPIM15";     AppName = "Outlook 2016";               Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409ONMC15";     AppName = "OneNote 2016";               Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409MSFB16";     AppName = "Skype for Business";         Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409IMCP01";     AppName = "Intune Company Portal";      Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409MSRD10";     AppName = "Remote Desktop v10";         Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409ONDR18";     AppName = "OneDrive";                   Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409WDAV00";     AppName = "Defender ATP";               Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409EDGE01";     AppName = "Edge";                       Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409TEAMS10";    AppName = "Teams 1.0 classic";          Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409TEAMS21";    AppName = "Teams 2.1";                  Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409OLIC02";     AppName = "Office Licensing Helper";    Channels = @("Production", "Preview", "Beta")}
        [PSCustomObject]@{AppID = "0409MSRH01";     AppName = "Remote Help";                Channels = @("Production")}
        [PSCustomObject]@{AppID = "0409MSQA01";     AppName = "Quick Assist";               Channels = @("Production")}
    )

    $filteredApps = $targetApps | Where-Object {$_.Channels -contains $Channel}

    $pos = 1
    $mauApps = @($filteredApps | ForEach-Object {
        Write-Progress -Id 0 -Activity "Processing Apps $pos of $($filteredApps.Count)" -Status "Channel: $Channel AppID: $($_.AppID) AppName: $($_.AppName)" -PercentComplete ($pos / $filteredApps.Count * 100)
        Get-MAUApp -AppID $_.AppID -AppName $_.AppName -ChannelURI $mauCdnUriBuilder.Uri -HttpClient $httpClient
        $pos++
    })
    Write-Progress -Id 0 -Activity "Processing Apps $pos of $($filteredApps.Count)" -Completed

    $httpClient.Dispose()

    return $mauApps
}