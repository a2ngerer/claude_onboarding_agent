#Requires -Version 5.1
<#
.SYNOPSIS
    Removes the Claude Onboarding Agent plugin on Windows.

.DESCRIPTION
    Deletes every skill junction under %USERPROFILE%\.claude\skills that
    points into the plugin directory, then removes the cloned repository
    itself. No changes to system-wide state.

.EXAMPLE
    irm https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/scripts/uninstall.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

$PluginDir  = Join-Path $HOME '.claude\plugins'
$PluginName = 'claude-onboarding-agent'
$SkillsDir  = Join-Path $HOME '.claude\skills'
$Target     = Join-Path $PluginDir $PluginName

Write-Host 'Uninstalling Claude Onboarding Agent...'

if (-not (Test-Path -LiteralPath $Target)) {
    Write-Host 'Not installed -- nothing to remove.'
    return
}

$SkillsSource = Join-Path $Target 'skills'
if (Test-Path -LiteralPath $SkillsSource) {
    Get-ChildItem -LiteralPath $SkillsSource -Directory | ForEach-Object {
        $skillName = $_.Name
        $linkPath  = Join-Path $SkillsDir $skillName

        if (-not (Test-Path -LiteralPath $linkPath)) { return }

        $existing = Get-Item -LiteralPath $linkPath -Force
        if (-not $existing.LinkType) { return }

        Remove-Item -LiteralPath $linkPath -Force
        Write-Host "  [ok] removed skill: $skillName"
    }
}

Remove-Item -LiteralPath $Target -Recurse -Force
Write-Host ''
Write-Host 'Claude Onboarding Agent removed successfully.'
