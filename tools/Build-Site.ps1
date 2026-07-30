param(
    [string]$OutputPath = "_site"
)

$ErrorActionPreference = "Stop"

function ConvertTo-HtmlText {
    param([AllowNull()][string]$Value)
    return [System.Net.WebUtility]::HtmlEncode($Value)
}

function New-SiteShell {
    param(
        [string]$Title,
        [string]$Main
    )

    return @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$([System.Net.WebUtility]::HtmlEncode($Title))</title>
    <link rel="stylesheet" href="assets/site/site.css">
  </head>
  <body>
    <header class="site-header">
      <div class="site-header__inner">
        <a class="brand" href="index.html">
          <span class="brand__mark">SICK</span>
          <span>SIM300 Documentation</span>
        </a>
        <nav class="nav" aria-label="Primary navigation">
          <a href="index.html">Manuals</a>
        </nav>
      </div>
    </header>
    <main class="site-main">
$Main
    </main>
    <footer class="site-footer">
      <span>&copy; <span data-current-year></span> Documentation project.</span>
    </footer>
    <script src="assets/site/site.js"></script>
  </body>
</html>
"@
}

function New-ManualVersionsHtml {
    param($Manifest)

    $versionLinks = @($Manifest.versions) | ForEach-Object {
        $version = ConvertTo-HtmlText $_.version
        $status = ConvertTo-HtmlText $_.status
        $date = ConvertTo-HtmlText $_.date
        $summary = ConvertTo-HtmlText $_.summary
        @"
          <li>
            <a href="$version/index.html">
              <span><strong>$version</strong> $summary</span>
              <span>$status $date</span>
            </a>
          </li>
"@
    }

    $title = ConvertTo-HtmlText $Manifest.title
    $description = ConvertTo-HtmlText $Manifest.description
    $latest = ConvertTo-HtmlText $Manifest.latest

    return @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$title versions</title>
    <link rel="stylesheet" href="../../assets/site/site.css">
  </head>
  <body>
    <header class="site-header">
      <div class="site-header__inner">
        <a class="brand" href="../../index.html">
          <span class="brand__mark">SICK</span>
          <span>SIM300 Documentation</span>
        </a>
        <nav class="nav" aria-label="Primary navigation">
          <a href="../../index.html">Manuals</a>
          <a href="index.html">Latest</a>
        </nav>
      </div>
    </header>
    <main class="site-main">
      <section class="hero">
        <p class="eyebrow">Manual versions</p>
        <h1>$title</h1>
        <p class="lead">$description</p>
        <p><a href="index.html">Open latest version ($latest)</a></p>
      </section>
      <ul class="version-list">
$($versionLinks -join "")
      </ul>
    </main>
    <footer class="site-footer">
      <span>&copy; <span data-current-year></span> Documentation project.</span>
    </footer>
    <script src="../../assets/site/site.js"></script>
  </body>
</html>
"@
}

function New-LatestRedirectHtml {
    param($Manifest)

    $title = ConvertTo-HtmlText $Manifest.title
    $description = ConvertTo-HtmlText $Manifest.description
    $latest = ConvertTo-HtmlText $Manifest.latest

    return @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="0; url=$latest/index.html">
    <title>$title latest</title>
    <link rel="stylesheet" href="../../assets/site/site.css">
  </head>
  <body>
    <header class="site-header">
      <div class="site-header__inner">
        <a class="brand" href="../../index.html">
          <span class="brand__mark">SICK</span>
          <span>SIM300 Documentation</span>
        </a>
        <nav class="nav" aria-label="Primary navigation">
          <a href="../../index.html">Manuals</a>
          <a href="versions.html">Versions</a>
        </nav>
      </div>
    </header>
    <main class="site-main">
      <section class="hero">
        <p class="eyebrow">Latest version</p>
        <h1>$title</h1>
        <p class="lead">$description</p>
        <p><a href="$latest/index.html">Open latest version ($latest)</a></p>
      </section>
    </main>
    <footer class="site-footer">
      <span>&copy; <span data-current-year></span> Documentation project.</span>
    </footer>
    <script src="../../assets/site/site.js"></script>
  </body>
</html>
"@
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$manualsRoot = Join-Path $repoRoot "manuals"
$assetsRoot = Join-Path $repoRoot "assets"
$resolvedOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $repoRoot $OutputPath
}

if (Test-Path $resolvedOutput) {
    Remove-Item -LiteralPath $resolvedOutput -Recurse -Force
}

New-Item -ItemType Directory -Path $resolvedOutput | Out-Null
Set-Content -LiteralPath (Join-Path $resolvedOutput ".nojekyll") -Value "" -Encoding ASCII

if (Test-Path $assetsRoot) {
    Copy-Item -Path $assetsRoot -Destination (Join-Path $resolvedOutput "assets") -Recurse -Force
}

$manualEntries = @()
$manifestFiles = Get-ChildItem -Path $manualsRoot -Filter "manifest.json" -Recurse -File |
    Sort-Object FullName

foreach ($manifestFile in $manifestFiles) {
    $manifest = Get-Content -Raw -LiteralPath $manifestFile.FullName | ConvertFrom-Json
    $manualRoot = Split-Path -Parent $manifestFile.FullName
    $slug = [string]$manifest.slug

    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw "Missing slug in $($manifestFile.FullName)"
    }

    $manualOutputRoot = Join-Path $resolvedOutput "manuals/$slug"
    New-Item -ItemType Directory -Path $manualOutputRoot -Force | Out-Null

    $versions = @($manifest.versions)
    if ($versions.Count -eq 0) {
        throw "No versions declared in $($manifestFile.FullName)"
    }

    $latestFound = $false
    foreach ($versionInfo in $versions) {
        $version = [string]$versionInfo.version
        if ([string]::IsNullOrWhiteSpace($version)) {
            throw "A version entry in $($manifestFile.FullName) is missing a version value"
        }

        $sourceVersionPath = Join-Path $manualRoot "versions/$version"
        $sourceIndex = Join-Path $sourceVersionPath "index.html"
        if (-not (Test-Path $sourceIndex)) {
            throw "Missing index.html for $slug $version at $sourceIndex"
        }

        Copy-Item -Path $sourceVersionPath -Destination (Join-Path $manualOutputRoot $version) -Recurse -Force

        if ($version -eq [string]$manifest.latest) {
            $latestFound = $true
        }
    }

    if (-not $latestFound) {
        throw "Latest version '$($manifest.latest)' is not declared in $($manifestFile.FullName)"
    }

    Set-Content -LiteralPath (Join-Path $manualOutputRoot "versions.html") -Value (New-ManualVersionsHtml -Manifest $manifest) -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $manualOutputRoot "index.html") -Value (New-LatestRedirectHtml -Manifest $manifest) -Encoding UTF8

    $manualEntries += [pscustomobject]@{
        Slug = $slug
        Title = [string]$manifest.title
        Description = [string]$manifest.description
        Latest = [string]$manifest.latest
        Versions = $versions
    }
}

$cards = $manualEntries | ForEach-Object {
    $title = ConvertTo-HtmlText $_.Title
    $description = ConvertTo-HtmlText $_.Description
    $slug = ConvertTo-HtmlText $_.Slug
    $latest = ConvertTo-HtmlText $_.Latest
    @"
        <a class="manual-card" href="manuals/$slug/index.html">
          <h2>$title</h2>
          <p>$description</p>
          <div class="manual-card__meta">
            <span class="badge">Latest $latest</span>
            <span class="badge">$(@($_.Versions).Count) version(s)</span>
          </div>
        </a>
"@
}

$main = @"
      <section class="hero">
        <p class="eyebrow">Public manuals</p>
        <h1>SICK SIM300 IO-Link Modbus Server Documentation</h1>
        <p class="lead">
          Versioned manuals, application notes, release documentation, and
          static resources for the SIM300 IO-Link Modbus Server AppSpace
          application.
        </p>
      </section>
      <section class="manual-grid" aria-label="Manual list">
$($cards -join "")
      </section>
"@

Set-Content -LiteralPath (Join-Path $resolvedOutput "index.html") -Value (New-SiteShell -Title "SICK SIM300 Documentation" -Main $main) -Encoding UTF8

Write-Host "Built static site at $resolvedOutput"
