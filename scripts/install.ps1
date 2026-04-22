#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the Claude Onboarding Agent plugin on Windows.

.DESCRIPTION
    Clones (or updates) the plugin repository under
    %USERPROFILE%\.claude\plugins\claude-onboarding-agent and creates a
    directory junction for every skill folder under
    %USERPROFILE%\.claude\skills so Claude Code discovers them at session
    start. Junctions are used instead of symbolic links so the script works
    without admin rights or Windows Developer Mode.

.EXAMPLE
    irm https://raw.githubusercontent.com/a2ngerer/claude_onboarding_agent/main/scripts/install.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

$PluginDir  = Join-Path $HOME '.claude\plugins'
$PluginName = 'claude-onboarding-agent'
$SkillsDir  = Join-Path $HOME '.claude\skills'
$RepoUrl    = 'https://github.com/a2ngerer/claude_onboarding_agent.git'
$Target     = Join-Path $PluginDir $PluginName

Write-Host 'Installing Claude Onboarding Agent...'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required but not found on PATH. Install Git for Windows from https://git-scm.com/download/win and retry."
}

New-Item -ItemType Directory -Force -Path $PluginDir | Out-Null
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

if (Test-Path -LiteralPath $Target) {
    Write-Host 'Already installed -- updating...'
    git -C $Target pull
} else {
    Write-Host 'Cloning repository...'
    git clone $RepoUrl $Target
}

Write-Host 'Linking skills to ~\.claude\skills\...'

$SkillsSource = Join-Path $Target 'skills'
Get-ChildItem -LiteralPath $SkillsSource -Directory | ForEach-Object {
    $skillName = $_.Name
    $linkPath  = Join-Path $SkillsDir $skillName

    if (Test-Path -LiteralPath $linkPath) {
        $existing = Get-Item -LiteralPath $linkPath -Force
        if ($existing.LinkType) {
            Remove-Item -LiteralPath $linkPath -Force
        } else {
            Write-Warning "  ! $skillName exists and is not a link -- skipping"
            return
        }
    }

    New-Item -ItemType Junction -Path $linkPath -Target $_.FullName | Out-Null
    Write-Host "  [ok] $skillName"
}

Write-Host ''
Write-Host 'Claude Onboarding Agent installed successfully.'
Write-Host ''
Write-Host 'Start a new Claude Code session and run: /onboarding'
