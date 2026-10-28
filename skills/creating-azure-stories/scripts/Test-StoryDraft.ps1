#Requires -Version 7
<#
.SYNOPSIS
    Lint gate for creating-azure-stories drafts. Exits 1 when any check fails.
.EXAMPLE
    pwsh -NoProfile -File Test-StoryDraft.ps1 -Path work-items/my-story.md -Tier Standard
#>
param(
    [Parameter(Mandatory)] [string] $Path,
    [Parameter(Mandatory)] [ValidateSet('XS', 'Standard', 'Large')] [string] $Tier
)

$ErrorActionPreference = 'Stop'
$text = (Get-Content -LiteralPath $Path -Raw) -replace "`r`n", "`n"
$lines = $text -split "`n"
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string] $Level, [string] $Check, [string] $Message) {
    $results.Add([pscustomobject]@{ Level = $Level; Check = $Check; Message = $Message })
}

$limits = @{
    XS       = @{ Words = 120; MinTitle = 4; MaxTitle = 8;  MinCriteria = 2; MaxCriteria = 3 }
    Standard = @{ Words = 300; MinTitle = 4; MaxTitle = 10; MinCriteria = 3; MaxCriteria = 5 }
    Large    = @{ Words = 500; MinTitle = 4; MaxTitle = 10; MinCriteria = 3; MaxCriteria = 5 }
}[$Tier]

# Code blocks: fenced with ``` or ~~~.
$blocks = @()
$inBlock = $false
$blockLines = 0
$bodyLines = [System.Collections.Generic.List[string]]::new()
foreach ($line in $lines) {
    if ($line -match '^\s*(```|~~~)') {
        if ($inBlock) { $blocks += $blockLines; $inBlock = $false } else { $inBlock = $true; $blockLines = 0 }
        continue
    }
    if ($inBlock) { $blockLines++ } else { $bodyLines.Add($line) }
}
if ($inBlock) { Add-Result FAIL 'Code' 'Unclosed code block.' }
if ($blocks.Count -gt 2) { Add-Result FAIL 'Code' "$($blocks.Count) code blocks; the limit is 2. Move scripts to attachments." }
for ($i = 0; $i -lt $blocks.Count; $i++) {
    if ($blocks[$i] -gt 6) { Add-Result FAIL 'Code' "Code block $($i + 1) has $($blocks[$i]) lines; the limit is 6." }
}

# Title.
$title = $bodyLines | Where-Object { $_ -match '^# ' } | Select-Object -First 1
if (-not $title) {
    Add-Result FAIL 'Title' 'No H1 title.'
} else {
    $titleWords = @(($title -replace '^# ', '').Trim() -split '\s+').Count
    if ($titleWords -lt $limits.MinTitle -or $titleWords -gt $limits.MaxTitle) {
        Add-Result WARN 'Title' "Title has $titleWords words; aim for $($limits.MinTitle)-$($limits.MaxTitle), without sacrificing clarity."
    }
}

# Sections.
$sections = @($bodyLines | Where-Object { $_ -match '^## ' } | ForEach-Object { ($_ -replace '^## ', '').Trim() })
$expected = @('Acceptance Criteria')
if ($Tier -ne 'XS') {
    $expected = @('Blocked By', 'Current State', 'Goal')
    if ($sections -contains 'Backing Content') { $expected += 'Backing Content' }
    $expected += 'Details'
    if ($sections -contains 'Kickoff Conversation') {
        $expected += 'Kickoff Conversation'
        Add-Result WARN 'Kickoff' 'Kickoff Conversation is only for stories the user agreed to keep short after the cold read kept growing them.'
    }
    $expected += 'Acceptance Criteria'
}
if (($sections -join '|') -ne ($expected -join '|')) {
    Add-Result FAIL 'Sections' "Found [$($sections -join ', ')]; expected [$($expected -join ', ')]."
}
if ($Tier -ne 'Large' -and ($bodyLines | Where-Object { $_ -match '^### ' })) {
    Add-Result FAIL 'Sections' 'H3 headings are only allowed in Large stories.'
}

# Split body from acceptance criteria.
$acIndex = [Array]::IndexOf([string[]] $bodyLines, '## Acceptance Criteria')
$storyBody = if ($acIndex -ge 0) { $bodyLines[0..($acIndex - 1)] } else { $bodyLines }
$criteriaLines = if ($acIndex -ge 0) { $bodyLines[($acIndex + 1)..($bodyLines.Count - 1)] } else { @() }

$criteria = @($criteriaLines | Where-Object { $_ -match '^\s*- \[ \]' }).Count
if ($criteria -lt $limits.MinCriteria -or $criteria -gt $limits.MaxCriteria) {
    Add-Result FAIL 'Criteria' "$criteria acceptance criteria; expected $($limits.MinCriteria)-$($limits.MaxCriteria)."
}

# Word count excludes the title, headings, and code blocks.
$prose = ($storyBody | Where-Object { $_ -notmatch '^#{1,3} ' }) -join ' '
$words = @($prose -split '\s+' | Where-Object { $_ -match '\w' }).Count
if ($words -gt $limits.Words) {
    Add-Result WARN 'Length' "$words body words; the $Tier goal is $($limits.Words). Keep necessary context and transitions; trim only when readability is preserved."
}

# Current State and Goal carry the briefing: 2-3 sentences each, read as a before and after.
function Get-Section([string] $Name) {
    $index = [Array]::IndexOf([string[]] $bodyLines, "## $Name")
    if ($index -lt 0) { return $null }
    $content = @()
    for ($i = $index + 1; $i -lt $bodyLines.Count -and $bodyLines[$i] -notmatch '^## '; $i++) { $content += $bodyLines[$i] }
    return ($content -join ' ').Trim()
}
function Get-SentenceCount([string] $Text) {
    return @(($Text -replace '`[^`]*`', 'code') -split '(?<=[.!?])\s+' | Where-Object { $_ -match '\w' }).Count
}
foreach ($name in 'Current State', 'Goal') {
    $section = Get-Section $name
    if ($null -ne $section) {
        $count = Get-SentenceCount $section
        if ($count -lt 2 -or $count -gt 3) {
            Add-Result WARN $name "$name has $count sentence(s); aim for 2-3."
        }
    }
}
$goal = Get-Section 'Goal'
if ($null -ne $goal) {
    if ($goal -notmatch '\b(should|will)\b') {
        Add-Result WARN 'Goal' 'Goal reads like the current state; state where we are trying to go ("should ...").'
    }
    if ($goal -match '`[^`]*/[^`]*`') {
        Add-Result WARN 'Goal' 'Goal names a file path; keep locations in Details and state the objective and intent here.'
    }
}
$backing = Get-Section 'Backing Content'
if ($null -ne $backing) {
    $backingWords = @($backing -split '\s+' | Where-Object { $_ -match '\w' }).Count
    if ($backingWords -gt 80) {
        Add-Result WARN 'Backing' "$backingWords Backing Content words; aim for 80. Keep only the background the reader needs before Details, or drop the section."
    }
}

# Links break when pasted into Azure DevOps.
if ($text -match '\]\([^)]+\)') { Add-Result FAIL 'Links' 'Markdown links found; use backticked paths instead.' }
if ($text -match '\[[^\]]*\b(title|Title|NUMBER|ID|path|Observable result)\b[^\]]*\]') {
    Add-Result WARN 'Placeholders' 'Possible unreplaced template placeholder.'
}

# Wording checks run on prose only, including criteria.
$allProse = ($bodyLines | Where-Object { $_ -notmatch '^#{1,3} ' }) -join "`n"
$failPhrases = [ordered]@{
    'Process narration' = '\b(I|we)\s+(found|verified|confirmed|ran|checked|probed)\b'
    'Evidence language' = '\b(verified against|probe[sd]?|audit(ed|s)?|source inspection)\b'
    'Defensive caveat'  = '\b(is not a claim|does not claim|this (story|item) does not establish|(was|were|is|are) not (been )?verified)\b'
    'Suggested evidence' = '\b(easiest to (show|demonstrate|reproduce)|could be (shown|demonstrated|reproduced)|a small (node |test )?script that)\b'
}
foreach ($name in $failPhrases.Keys) {
    $found = [regex]::Matches($allProse, $failPhrases[$name], 'IgnoreCase') | ForEach-Object Value | Select-Object -Unique
    if ($found) { Add-Result FAIL 'Wording' "$($name): $($found -join ', ')" }
}
# "The attached X" is only fine after the story has said what is attached.
$firstReference = [regex]::Match($allProse, '\bthe attached\b', 'IgnoreCase')
$firstIntroduction = [regex]::Match($allProse, '\bis attached\b|\battached (as|to this story)\b', 'IgnoreCase')
if ($firstReference.Success -and (-not $firstIntroduction.Success -or $firstReference.Index -lt $firstIntroduction.Index)) {
    Add-Result FAIL 'Wording' 'Unintroduced reference: "the attached" appears before the story says what is attached.'
}

$warnPhrases = [ordered]@{
    'Filler' = '\b(ensure[sd]?|robust|comprehensive|leverag(e|es|ing)|seamless(ly)?|holistic|it is important to note)\b'
    'Jargon' = '\b(contract|boundary|focused (coverage|tests?|verification|scope|change)|representative|preserve existing)\b'
    'Backstory' = '\b(from before|used to|no longer|originally|previously|anymore|the old|(was|were|got|been) (swapped|changed|renamed|moved|reordered|dropped))\b'
}
foreach ($name in $warnPhrases.Keys) {
    $found = [regex]::Matches($allProse, $warnPhrases[$name], 'IgnoreCase') | ForEach-Object Value | Select-Object -Unique
    if ($found) { Add-Result WARN 'Wording' "$($name): $($found -join ', ')" }
}
$emDashes = ([regex]::Matches($allProse, '—')).Count
if ($emDashes -gt 3) { Add-Result WARN 'Wording' "$emDashes em dashes; rewrite some as separate sentences." }

$sentences = @(($prose -replace '`[^`]*`', 'code') -split '(?<=[.!?])\s+' | Where-Object { $_ -match '\w' })
if ($sentences.Count -gt 0) {
    $average = [math]::Round($words / $sentences.Count, 1)
    if ($average -gt 25) { Add-Result WARN 'Wording' "Sentences average $average words; aim for 25 or fewer." }
}

# Report.
"Story lint: $Path (tier $Tier, $words body words, $criteria criteria, $($blocks.Count) code blocks)"
if ($results.Count -eq 0) { 'PASS: no findings.'; exit 0 }
$results | ForEach-Object { "$($_.Level) [$($_.Check)] $($_.Message)" }
$failures = @($results | Where-Object Level -eq 'FAIL').Count
if ($failures -gt 0) { "Result: $failures failure(s). Fix them, or proceed only with a stated reason."; exit 1 }
'Result: warnings only.'
exit 0
