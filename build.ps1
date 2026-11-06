$ErrorActionPreference = 'Stop'
$dist = Join-Path $PSScriptRoot docs
$records = foreach ($file in Get-ChildItem "$dist/kb/*.md") {
    $source = Get-Content -LiteralPath $file.FullName -Raw
    $parts = $source -split '(?m)^---\r?\n', 3
    if ($parts.Count -ne 3 -or $parts[1] -notmatch "(?m)^id: $($file.BaseName)\r?$") {
        throw "Invalid record: $($file.Name)"
    }
    $body = $parts[2] -replace '\[Back to the main page\]\(\.\./README\.md\)', '[All zerostars](../index.html)'
    $html = (ConvertFrom-Markdown -InputObject $body).Html -replace 'href="([0-9a-f-]{36})\.md"', 'href="$1.html"'
    $title = [regex]::Match($body, '(?m)^# (.+)').Groups[1].Value.Trim()
    $summary = [regex]::Match($parts[1], '(?m)^gist: (.+)').Groups[1].Value.Trim().Trim('"')
    [pscustomobject]@{ Id = $file.BaseName; Title = $title; Summary = $summary; Html = $html }
}

function Write-Page($path, $title, $prefix, $body) {
    $title = [System.Net.WebUtility]::HtmlEncode($title)
    @"
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title · ZeroStar.IO</title>
<link rel="stylesheet" href="${prefix}style.css">
<header><a href="${prefix}index.html">✦ ZeroStar.IO</a></header>
<main>$body</main>
</html>
"@ | Set-Content -LiteralPath $path -Encoding utf8
}

$cards = foreach ($record in $records) {
    $title = [System.Net.WebUtility]::HtmlEncode($record.Title)
    $summary = [System.Net.WebUtility]::HtmlEncode($record.Summary)
    $id = $record.Id
    Write-Page "$dist/kb/$id.html" $record.Title '../' "<article>$($record.Html)</article><footer><code>$id</code> · <a href='$id.md'>Markdown source</a></footer>"
    "<li><h2><a href='kb/$id.html'>$title</a></h2><p>$summary</p><code>$id</code></li>"
}
Write-Page "$dist/index.html" 'Knowledge base' '' "<h1>Knowledge base</h1><p>Foundational documents by Dan Stace.</p><ul class='records'>$($cards -join [Environment]::NewLine)</ul>"
