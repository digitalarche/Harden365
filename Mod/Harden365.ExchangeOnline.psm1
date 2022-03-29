<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.ExchangeOnline.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 12/02/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Exchange Online Protection

    .DESCRIPTION
        Create SharedMailbox for alerts
        Create group for autoforward excluded
        Create group for Antispam strict policy
        Create Antispam Strict Policy and Rule
        Create Antispam Standard Policy and Rule
        Create Antimalware Policy and Rule
        Create transport rules to warm user for Office files with macro
        Create transport rules to block AutoForwarding mail out Organization
        Enable Unified Audit Log
#>


Function Start-EOPAlertsMailbox {
     <#
        .Synopsis
         create shared mailbox for alerts
        
        .Description
         This function will create shared mailbox for alerts 
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Alerts Mailbox",
    [String]$Alias = "AlertsMailbox"
)

Write-LogSection 'EXCHANGE ONLINE PROTECTION' -NoHostOutput

#SCRIPT
$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name
    if ((Get-EXOMailbox).PrimarySmtpAddress -eq "$alias@$DomainOnM365")
        {
        Write-LogWarning "Mailbox '$alias@$DomainOnM365' already created!"
    }
    else { 
            Try {
            New-Mailbox -Name $Name -Alias "AlertsMailbox" �Shared -PrimarySmtpAddress "$alias@$DomainOnM365"
            Set-Mailbox -Identity "$alias@$DomainOnM365" -HiddenFromAddressListsEnabled $true
            
            #DMARC Config
            $Domains=(Get-AcceptedDomain | Where-Object { $_.DomainName -notmatch "onmicrosoft.com"}).Name
            foreach ($Domain in $Domains) {
            Set-Mailbox -Identity "$alias@$DomainOnM365" -EmailAddresses @{Add="d@$Domain"}
            }
            Write-LogInfo "Mailbox '$alias@$DomainOnM365' created"
            }
                 Catch {
                        Write-LogError "Mailbox '$alias@$DomainOnM365' not created"
                        }
          }
}


Function Start-EOPAutoForwardGroup {
     <#
        .Synopsis
         Create group for autoforward excluded
        
        .Description
         This function will create new group for Autoforward excluded
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - GP AutoForward Exclude",
    [String]$Alias = "gp_autoforward_exclude",
    [String]$Members = ""
)


#SCRIPT
$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name
$GroupEOL=(Get-DistributionGroup | Where-Object { $_.DisplayName -eq $Name}).Name
    if (-not $GroupEOL)
        {
        Try {
            New-DistributionGroup -Name $Name -Type "Security" -PrimarySmtpAddress $Alias@$DomainOnM365 | Set-DistributionGroup -HiddenFromAddressListsEnabled $true
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


Function Start-EOPAntispamGroupStrict {
     <#
        .Synopsis
         Create group for Antispam strict policy
        
        .Description
         This function will create new group for Antispam strict policy

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - GP Antispam strict",
    [String]$Alias = "gp_antispam_strict",
    [String]$Members = ""
)


#SCRIPT
$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name
$GroupEOL=(Get-DistributionGroup | Where-Object { $_.DisplayName -eq $Name}).Name
    if (-not $GroupEOL)
        {
        Try {
            New-DistributionGroup -Name $Name -Type "Security" -PrimarySmtpAddress $Alias@$DomainOnM365 | Set-DistributionGroup -HiddenFromAddressListsEnabled $true
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


Function Start-EOPAntispamPolicyStrict {
     <#
        .Synopsis
         Create Antispam Strict Policy and Rule
        
        .Description
         This function will create new Antispam Strict Policy
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$PolicyInboundName = "Harden365 - AntiSpam Inbound Policy Strict",
    [String]$RuleInboundName = "Harden365 - AntiSpam Inbound Rule Strict",
    [String]$PolicyOutboundName = "Harden365 - AntiSpam Outbound Policy Strict",
    [String]$RuleOutboundName = "Harden365 - AntiSpam Outbound Rule Strict",
    [String]$HighConfidenceSpamAction = "Quarantine",
    [String]$SpamAction = "MoveToJmf",
    [String]$BulkThreshold = "4",
    [String]$QuarantineRetentionPeriod = "30",
    [Boolean]$EnableEndUserSpamNotifications = $true,
    [String]$BulkSpamAction = "MoveToJmf",
    [String]$PhishSpamAction = "Quarantine",
    [String]$RecipientLimitExternalPerHour = "400",
	[String]$RecipientLimitInternalPerHour = "800",
	[String]$RecipientLimitPerDay = "800",
	[String]$ActionWhenThresholdReached = "BlockUser",
	[String]$GroupStrict = "Harden365 - GP Antispam strict",
	[String]$Priority = "0"
)


$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name

#SCRIPT INBOUND
    if ((Get-HostedContentFilterRule).Name -ne $RuleInboundName)
    {
        Try { 
            New-HostedContentFilterPolicy -Name $PolicyInboundName -HighConfidenceSpamAction $HighConfidenceSpamAction -SpamAction $SpamAction -BulkThreshold $BulkThreshold -QuarantineRetentionPeriod $QuarantineRetentionPeriod -EnableEndUserSpamNotifications $EnableEndUserSpamNotifications -BulkSpamAction $BulkSpamAction -PhishSpamAction $PhishSpamAction
            write-LogInfo "$PolicyInboundName created"
            New-HostedContentFilterRule -Name $RuleInboundName -HostedContentFilterPolicy $PolicyInboundName -Priority $Priority -SentToMemberOf $GroupStrict
            Write-LogInfo "$RuleInboundName created"
        } Catch {
                Write-LogError "$PolicyInboundName not created!"
                }
    } else
    {
         Write-LogWarning "$PolicyInboundName already created!"
         }      


#SCRIPT OUTBOUND
    if ((Get-HostedOutboundSpamFilterRule).name -ne $RuleOutboundName)
    {
        Try { 
            New-HostedOutboundSpamFilterPolicy -Name $PolicyOutboundName -RecipientLimitExternalPerHour $RecipientLimitExternalPerHour -RecipientLimitInternalPerHour $RecipientLimitInternalPerHour -RecipientLimitPerDay $RecipientLimitPerDay -ActionWhenThresholdReached $ActionWhenThresholdReached
            Write-LogInfo "$PolicyOutboundName created"
            New-HostedOutboundSpamFilterRule -Name $RuleOutboundName -HostedOutboundSpamFilterPolicy $PolicyOutboundName -Priority $Priority -FromMemberOf $GroupStrict
            Write-LogInfo "$RuleOutboundName created"
        } Catch {
                Write-LogError "$PolicyOutboundName not created!"
                }
    } else
    {
         Write-LogWarning "$PolicyOutboundName already created!"
         }
}


Function Start-EOPAntispamPolicyStandard {
     <#
        .Synopsis
         Create Antispam Standard Policy and Rule
        
        .Description
         This function will create new Antispam Standard Policy

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$PolicyInboundName = "Harden365 - AntiSpam Inbound Policy Standard",
    [String]$RuleInboundName = "Harden365 - AntiSpam Inbound Rule Standard",
    [String]$PolicyOutboundName = "Harden365 - AntiSpam Outbound Policy Standard",
    [String]$RuleOutboundName = "Harden365 - AntiSpam Outbound Rule Standard",
    [String]$HighConfidenceSpamAction = "Quarantine",
    [String]$SpamAction = "MoveToJmf",
    [String]$BulkThreshold = "6",
    [String]$QuarantineRetentionPeriod = "30",
    [Boolean]$EnableEndUserSpamNotifications = $true,
    [String]$BulkSpamAction = "MoveToJmf",
    [String]$PhishSpamAction = "Quarantine",
    [String]$RecipientLimitExternalPerHour = "500",
	[String]$RecipientLimitInternalPerHour = "1000",
	[String]$RecipientLimitPerDay = "1000",
	[String]$ActionWhenThresholdReached = "BlockUser",
	[String]$ExceptIfFromMemberOf = "",
	[String]$Priority = "0"
)


$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name

#SCRIPT INBOUND
    if ((Get-HostedContentFilterRule).name -ne $RuleInboundName)
    {
        Try { 
            Set-HostedContentFilterPolicy -Identity "Default" -HighConfidenceSpamAction $HighConfidenceSpamAction -SpamAction $SpamAction -BulkThreshold $BulkThreshold -QuarantineRetentionPeriod $QuarantineRetentionPeriod -EnableEndUserSpamNotifications $EnableEndUserSpamNotifications -BulkSpamAction $BulkSpamAction -PhishSpamAction $PhishSpamAction
            New-HostedContentFilterPolicy -Name $PolicyInboundName -HighConfidenceSpamAction $HighConfidenceSpamAction -SpamAction $SpamAction -BulkThreshold $BulkThreshold -QuarantineRetentionPeriod $QuarantineRetentionPeriod -EnableEndUserSpamNotifications $EnableEndUserSpamNotifications -BulkSpamAction $BulkSpamAction -PhishSpamAction $PhishSpamAction
            Write-LogInfo "$PolicyInboundName created"
            New-HostedContentFilterRule -Name $RuleInboundName -HostedContentFilterPolicy $PolicyInboundName -Priority $Priority -RecipientDomainIs ((Get-AcceptedDomain).Name)
            Write-LogInfo "$RuleInboundName created"
        } Catch {
                Write-LogError "$PolicyInboundName not created!"
                }
    } else
    {
         Write-LogWarning "$PolicyInboundName already created!"
         }

#SCRIPT OUTBOUND
    if ((Get-HostedOutboundSpamFilterRule).name -ne $RuleOutboundName)
    {
        Try { 
            Set-HostedOutboundSpamFilterPolicy -Identity "Default" -RecipientLimitExternalPerHour $RecipientLimitExternalPerHour -RecipientLimitInternalPerHour $RecipientLimitInternalPerHour -RecipientLimitPerDay $RecipientLimitPerDay -ActionWhenThresholdReached $ActionWhenThresholdReached
            New-HostedOutboundSpamFilterPolicy -Name $PolicyOutboundName -RecipientLimitExternalPerHour $RecipientLimitExternalPerHour -RecipientLimitInternalPerHour $RecipientLimitInternalPerHour -RecipientLimitPerDay $RecipientLimitPerDay -ActionWhenThresholdReached $ActionWhenThresholdReached
            Write-LogInfo "$PolicyOutboundName created"
            New-HostedOutboundSpamFilterRule -Name $RuleOutboundName -HostedOutboundSpamFilterPolicy $PolicyOutboundName -Priority $Priority -SenderDomainIs ((Get-AcceptedDomain).Name)
            Write-LogInfo "$RuleOutboundName created"
            if ($ExceptIfFromMemberOf -ne ""){
            Set-HostedOutboundSpamFilterPolicy -Identity $PolicyOutboundName -ExceptIfFromMemberOf $ExceptIfFromMemberOf}
            Write-LogInfo "$PolicyInboundName created"
        } Catch {
                Write-LogError "$PolicyInboundName not created!"
                }
    } else
    {
         Write-LogWarning "$PolicyInboundName already created!"
         }
}


Function Start-EOPAntiMalwarePolicy {
     <#
        .Synopsis
         Create Antimalware Policy and Rule
        
        .Description
         This function will create new AntiMalware Policy
        
        .Parameter DsiAgreement
         YES if the DSI is informed and agreed.

        .Notes
         Version: 01.00 -- 
         
    #>


	param(
	[Parameter(Mandatory = $false)]
	[String]$PolicyName = "Harden365 - Malware Filter Policy",
    [String]$RuleName = "Harden365 - Malware Rule Policy",
    [String]$Action = "DeleteMessage",
    [String]$Alerts = "alertsmailbox",
    [Boolean]$EnableFileFilter = $true,
    [Boolean]$ZapEnabled = $true,
    [Boolean]$EnableExternalSenderAdminNotifications = $true,
    [Boolean]$EnableInternalSenderAdminNotifications = $true,
    [String]$Priority = "0"
)

$FileTypes=@("ace","ade","ani","app","bas","bat","chm","cmd","com","cpl","crt","exe","hlp","hta","inf","ins","isp","jar","js","jse","lnk","mda","mdb","mde","mdz","msc","msi","msp","mst","pcd","pif","reg","scr","sct","shs","url","vb","vbe","vbs","wsc","wsf","ws")

#SCRIPT
$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name
    if ((Get-MalwareFilterRule).name -ne $RuleName)
    {
        Try { 
            Set-MalwareFilterPolicy -Identity "Default" -EnableFileFilter $EnableFileFilter
            New-MalwareFilterPolicy -Name $PolicyName -Action $Action -EnableFileFilter $EnableFileFilter -ZapEnabled $ZapEnabled -EnableExternalSenderAdminNotifications $EnableExternalSenderAdminNotifications -ExternalSenderAdminAddress "$Alerts@$DomainOnM365" -EnableInternalSenderAdminNotifications $EnableInternalSenderAdminNotifications -InternalSenderAdminAddress "$Alerts@$DomainOnM365" -FileTypes $FileTypes
            Write-LogInfo "$PolicyName created"
            New-MalwareFilterRule -Name $RuleName -MalwareFilterPolicy $PolicyName -Priority $Priority -RecipientDomainIs ((Get-AcceptedDomain).Name)
            Write-LogInfo "$RuleName created"
        } Catch {
                Write-LogError "$PolicyName not created"
                }
    } else
    {
         Write-LogWarning "$PolicyName already created!"
         }
}


Function Start-EOPAntiMacroRule {
     <#
        .Synopsis
         Create transport rules to warm user for Office files with macro.
        
        .Description
         This function will create new AntiMacro Policy

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$RuleName = "Harden365 - Anti-ransomware warn users",
    [String]$Mode = "Enforce",
    [String]$RuleErrorAction = "Ignore",
    [String]$ApplyHtmlDisclaimerLocation = "Prepend",
    [String]$ApplyHtmlDisclaimerFallbackAction = "Wrap",
	[String]$Priority = "0"
)

$AttachmentExtensionMatchesWords = @("dotm","docm","xlsm","sltm","xla","xlam","xll","pptm","potm","ppam","ppsm","sldm")

# DISCLAIMER EN
$WarmDisclaimerEN="<table border=0 cellspacing=0 cellpadding=0 align=left width=`"100%`">
<tr>
<td style='background:#bba555;padding:5.25pt 5.5pt 5.25pt 1.5pt'></td>
<td width=`"100%`" style='width:100.0%;background:#ffe599;padding:5.25pt 
3.75pt 5.25pt 11.25pt; word-wrap:break-word' cellpadding=`"7px 5px 7px
 15px`" color=`"#212121`">
<div><p><span style='font-size:11pt;font-family:Arial,sans-serif;color:
#212121'>
<b>CAUTION:</b> Do not open these types of files�unless you were expecting them�because the files may contain malicious code and knowing the sender isn't a guarantee of safety.
</span></p></div>
</td></tr></table>"

# DISCLAIMER FR
$WarmDisclaimerFR="<table border=0 cellspacing=0 cellpadding=0 align=left width=`"100%`">
<tr>
<td style='background:#bba555;padding:5.25pt 5.5pt 5.25pt 1.5pt'></td>
<td width=`"100%`" style='width:100.0%;background:#ffe599;padding:5.25pt 
3.75pt 5.25pt 11.25pt; word-wrap:break-word' cellpadding=`"7px 5px 7px
 15px`" color=`"#212121`">
<div><p><span style='font-size:11pt;font-family:Arial,sans-serif;color:
#212121'>
<b>CAUTION:</b> N�ouvrez pas ces types de fichiers, sauf si vous vous y attendiez, car les fichiers peuvent contenir du code malveillant et conna�tre l�exp�diteur n�est pas une garantie de s�curit�.
</span></p></div>
</td></tr></table>"


$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name

#SCRIPT
    if ((Get-TransportRule).name -eq $RuleName)
    {
     Write-LogWarning "$RuleName already created"
     }
     else{
      Try { 
           New-TransportRule -Name $RuleName -Priority $Priority -Mode $Mode -RuleErrorAction $RuleErrorAction -AttachmentExtensionMatchesWords $AttachmentExtensionMatchesWords -ApplyHtmlDisclaimerLocation $ApplyHtmlDisclaimerLocation -ApplyHtmlDisclaimerText "$WarmDisclaimerFR" -ApplyHtmlDisclaimerFallbackAction $ApplyHtmlDisclaimerFallbackAction
           Start-Sleep -Seconds 2
           Write-LogInfo "$RuleName created"
           } Catch {
                Write-LogError "$RuleName not created!"
                }
}         
}


Function Start-EOPAutoForwardRule {
     <#
        .Synopsis
         Create transport rules to block AutoForwarding mail out Organization
        
        .Description
         This function will create new AutoForward Policy

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$RuleName = "Harden365 - Prevent auto forwarding of email to external domains",
    [String]$Mode = "Enforce",
    [Boolean]$Enabled = $false,
    [String]$RuleErrorAction = "Ignore",
    [String]$FromScope = "InOrganization",
    [String]$SentToScope = "NotInOrganization",
    [String]$MessageTypeMatches = "AutoForward",
    [String]$GroupExclude = "gp_autoforward_exclude",
	[String]$Priority = "1"
)


#SCRIPT
$ForwardDisclaimerEN="Auto-forwarding email outside this organization is prevented for security reasons."
$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name
    if ((Get-TransportRule).name -eq $RuleName)
    {
         Write-LogWarning "$RuleName already created"
    } else
    {
            Try { 
            New-TransportRule -Name $RuleName -Priority $Priority -Mode $Mode -Enabled $Enabled -RuleErrorAction $RuleErrorAction  -FromScope $FromScope -SentToScope $SentToScope -MessageTypeMatches $MessageTypeMatches -RejectMessageReasonText "$ForwardDisclaimerEN" -ExceptIfFromMemberOf "$GroupExclude@$DomainOnM365"
            Start-Sleep -Seconds 2
            Write-LogInfo "$RuleName created"
            } Catch {
                Write-LogError "$RuleName not created"
                }
    }
}


Function Start-EOPCheckAutoForward {
     <#
        .Synopsis
         check autoforwarding
        
        .Description
         This function will check autoforwarding

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)

#SCRIPT

            # Check and add exclusion in group autoforwarding EOL CONSOLE
            $Forwards=((Get-Mailbox -ResultSize Unlimited) | ? { ($_.DeliverToMailboxAndForward -eq $true) -or ($_.ForwardingAddress -ne $null) -or ($_.ForwardingsmtpAddress -ne $null)}) | ForEach-Object {
            if ($_ -ne $null) {
            #Write-Host "Autoforwarding found in $($_.UserPrincipalName)  to $($_.ForwardingAddress -split "SMTP:") $($_.ForwardingSmtpAddress -split "SMTP:")"}}
            Write-LogWarning "Autoforwarding found in $($_.UserPrincipalName)  to $($_.ForwardingAddress -split "SMTP:") $($_.ForwardingSmtpAddress -split "SMTP:")"
            #Add-DistributionGroupMember -Identity "$GroupExclude@$DomainOnM365" -Member "$Forward"
            #Write-LogInfo "Add $($_.UserPrincipalName) to member of group $GroupExclude"}
            }
                                    
            # Check autoforwarding in all inbox rule
            Write-LogInfo "Check autoforwarding in all inbox rule"
            $rules=Get-Mailbox -ResultSize Unlimited| ForEach-Object {Get-InboxRule -Mailbox $PSItem.primarysmtpaddress} | Out-Null
            $forwardingRules = $rules | Where-Object {($_.forwardto -ne $null) -or ($_.forwardsattachmentto -ne $null) -or ($_.Redirectto -ne $null)}
            foreach ($rule in $forwardingRules) {
            #Write-Host "Mailbox '$($rule.MailboxOwnerId)' forward to '$($rule.ForwardTo)$($rule.RedirectTo)' in inbox rule '$($rule.Name)'"}
            Write-LogWarning "Mailbox '$($rule.MailboxOwnerId)' forward to '$($rule.ForwardTo)$($rule.RedirectTo)' in inbox rule '$($rule.Name)'"
            }
}
}


Function Start-EOPEnableAuditLog {
     <#
        .Synopsis
         Enable Unified Audit Log
        
        .Description
         This function will enable Unified Audit Log

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)


#SCRIPT
        if ((Get-OrganizationConfig).isDehydrated -eq $true)
    {
        Try { 
            Enable-OrganizationCustomization -ErrorAction SilentlyContinue
            Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -Force
            Write-LogInfo "Unified Audit Log enable"
        } Catch {
                Write-LogError "Unified Audit Log not enabled!"
                }

    } elseif ((Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled -eq $False)
    {
        Try { 
            Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -Force
            Write-LogInfo "Unified Audit Log enable"
        } Catch {
                Write-LogError "Unified Audit Log not enabled!"
                }
    } else
    {
         Write-LogWarning "Unified Audit Log already enabled!"
         }
Write-LogSection '' -NoHostOutput
}