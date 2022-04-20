<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.CA.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 01/18/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Conditional Access

    .DESCRIPTION
        Create CA for admins connection
        Create group for exclude users
        Create CA for users connection
        Create group for legacy authentification
        Create CA for legacy authentification
#>

Function Start-GroupMFAUsersExclude {
     <#
        .Synopsis
         Create group for exclude users.
        
        .Description
         This function will create new group for exclude MFA.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - MFA Users Exclude",
    [String]$mailNickName = "H365-MFAExclude"
)

Write-LogSection 'CONDITIONAL ACCESS' -NoHostOutput

#SCRIPT
$GroupAAD=Get-AzureADGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-AzureADGroup -Description "$Name" -DisplayName "$Name" -MailEnabled $false -SecurityEnabled $true -MailNickName $MailNickName
            Write-LogInfo "Group '$Name' created"
            }
                 Catch {
                        Write-LogError "Group '$Name' not created"
                        }
    }
    else { 
        Write-LogWarning "Group '$Name' already created!"
          }
}

Function Start-LegacyAuthGroupExclude {
     <#
        .Synopsis
         Create group for legacy authentification.
        
        .Description
         This function will create new group for exclude LegacyAuth .

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Legacy Authentification Exclude",
    [String]$mailNickName = "H365-LegacyExclude"
)


#SCRIPT
$GroupAAD=Get-AzureADGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-AzureADGroup -Description "$Name" -DisplayName "$Name" -MailEnabled $false -SecurityEnabled $true -MailNickName $MailNickName
            Write-LogInfo "Group '$Name' created"
            }
                 Catch {
                        Write-LogError "Group '$Name' not created"
                        }
    }
    else { 
        Write-LogWarning "Group '$Name' already created!"
          }
}

Function Start-LegacyAuthPolicy {
     <#
        .Synopsis
         Create CA for legacy authentification.
        
        .Description
         This function will create Conditional Access Block for Legacy auth.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Block Legacy Authentification",
	[String]$GroupExclude = "Harden365 - Legacy Authentification Exclude"
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name
    if (-not $CondAccPol){
        Try {
            $Conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $Conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $Conditions.Applications.IncludeApplications = "All"
            $Conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $Conditions.Users.IncludeUsers = "All"
            $Conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $Conditions.ClientAppTypes = @('ExchangeActiveSync', 'Other')
            $Controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $Controls._Operator = "OR"
            $Controls.BuiltInControls = "Block"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created"
                  }
 }

Function Start-MFAAdmins {
     <#
        .Synopsis
         Create CA for admins connection.
        
        .Description
         This function will create Conditionnal Access MFA for Admin roles .

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - MFA Admins"
)


#SCRIPT
$ExcludeCARoles = (Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Directory Synchronization Accounts"}).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeRoles = (Get-AzureADDirectoryRoleTemplate).ObjectId
            $conditions.Users.ExcludeRoles = $ExcludeCARoles
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $controls._Operator = "OR"
            $controls.BuiltInControls = @('MFA')
            $sessions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSessionControls
            $sessions.SignInFrequency = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSignInFrequency
            $sessions.SignInFrequency.Value = "9"
            $sessions.SignInFrequency.Type = "Hours"
            $sessions.SignInFrequency.IsEnabled = "true"
            $sessions.PersistentBrowser = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPersistentBrowser
            $sessions.PersistentBrowser.Mode = "Never"
            $sessions.PersistentBrowser.IsEnabled = "true"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls -SessionControls $sessions
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
}

Function Start-MFAUsers {
     <#
        .Synopsis
         Create CA for users connection.
        
        .Description
         This function will create Conditional Access MFA for Users.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - MFA Users",
	[String]$GroupExclude = "Harden365 - MFA Users Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Applications.ExcludeApplications = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Intune'").AppId,(Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Intune Enrollment'").AppId
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = "GuestsOrExternalUsers",(Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            #$conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.Users.ExcludeRoles = (Get-AzureADDirectoryRoleTemplate).ObjectId
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
            $conditions.Locations.IncludeLocations = "All"
            $conditions.Locations.ExcludeLocations = "Alltrusted"
            $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $controls._Operator = "OR"
            $controls.BuiltInControls = @('MFA')
            $sessions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSessionControls
            $sessions.SignInFrequency = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSignInFrequency
            $sessions.SignInFrequency.Value = "14"
            $sessions.SignInFrequency.Type = "Days"
            $sessions.SignInFrequency.IsEnabled = "true"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls -SessionControls $sessions
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-BlockUnmanagedDownloads {
     <#
        .Synopsis
         Create CA for block downloads in unmanaged devices.
        
        .Description
         This function will create Conditional Access to block downloads in unmanaged devices.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Block Unmanaged File Downloads",
	[String]$GroupExclude = "Harden365 - BlockUnmanagedDownloads Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Office 365 Exchange Online'").AppId,(Get-AzureADServicePrincipal -Filter "DisplayName eq 'Office 365 SharePoint Online'").AppId
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.ClientAppTypes = @('Browser')
            $sessions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSessionControls
            $sessions.ApplicationEnforcedRestrictions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationEnforcedRestrictions
            $sessions.ApplicationEnforcedRestrictions.IsEnabled = "true"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -SessionControls $sessions
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-UnsupportedDevicePlatforms {
     <#
        .Synopsis
         Create CA for Unsupported Device Platforms.
        
        .Description
         This function will create Conditional Access to Unsupported Device Platforms.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Unsupported Device Platforms",
	[String]$GroupExclude = "Harden365 - Unsupported Device Platforms Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name
    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
            $conditions.Platforms.IncludePlatforms = "All"
            $conditions.Platforms.ExcludePlatforms = @('Android','IOS','Windows','MacOS')
            $Controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $Controls._Operator = "OR"
            $Controls.BuiltInControls = "Block"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}