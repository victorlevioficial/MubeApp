param(
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

function Resolve-BrowserExe {
  $candidates = @(
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
  )
  foreach ($path in $candidates) {
    if (Test-Path $path) {
      return $path
    }
  }
  throw 'No compatible browser found. Install Edge or Chrome to print PDFs.'
}

function Convert-MarkdownToHtmlFragment {
  param(
    [Parameter(Mandatory = $true)][string]$MarkdownPath
  )
  $html = (& npx --yes marked -i $MarkdownPath --gfm | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($html)) {
    throw "Failed to convert markdown to HTML for: $MarkdownPath"
  }
  return $html
}

function Get-ColorGridHtml {
  param(
    [Parameter(Mandatory = $true)][string]$MarkdownText
  )
  $matchList = [regex]::Matches($MarkdownText, '#(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})\b')
  $seen = New-Object 'System.Collections.Generic.HashSet[string]'
  $colors = New-Object 'System.Collections.Generic.List[string]'

  foreach ($m in $matchList) {
    $hex = $m.Value.ToUpperInvariant()
    if ($seen.Add($hex)) {
      $colors.Add($hex) | Out-Null
    }
    if ($colors.Count -ge 14) {
      break
    }
  }

  if ($colors.Count -eq 0) {
    return ''
  }

  $items = foreach ($c in $colors) {
@"
<div class="swatch">
  <div class="swatch-color" style="background: $c;"></div>
  <div class="swatch-label">$c</div>
</div>
"@
  }

@"
<section class="palette">
  <h2>Palette Extract</h2>
  <div class="swatch-grid">
    $($items -join "`n")
  </div>
</section>
"@
}

function New-DocumentHtml {
  param(
    [Parameter(Mandatory = $true)][string]$Title,
    [Parameter(Mandatory = $true)][string]$Subtitle,
    [Parameter(Mandatory = $true)][string]$SourceLabel,
    [Parameter(Mandatory = $true)][string]$GeneratedAt,
    [AllowEmptyString()][string]$ColorGridHtml = '',
    [Parameter(Mandatory = $true)][string]$BodyHtml
  )
@"
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$Title - $Subtitle</title>
  <style>
    @page {
      size: A4;
      margin: 16mm 14mm 18mm 14mm;
    }
    :root {
      --bg: #0b0b0d;
      --surface: #15151a;
      --ink: #f6f6f8;
      --ink-dim: #b8bbc2;
      --line: #2a2f39;
      --accent: #d40055;
      --accent-2: #ff5c8d;
      --ok: #27ae60;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      color: #111;
      font-family: "Inter", "Segoe UI", Arial, sans-serif;
      line-height: 1.5;
      background: white;
    }
    .cover {
      min-height: 225mm;
      background:
        radial-gradient(1300px 420px at -10% -10%, rgba(212,0,85,.33), transparent 62%),
        radial-gradient(900px 360px at 100% 0%, rgba(255,92,141,.23), transparent 56%),
        linear-gradient(145deg, var(--bg), #11131a 52%, #171722);
      color: var(--ink);
      border-radius: 16px;
      padding: 34mm 14mm 16mm;
      position: relative;
      overflow: hidden;
    }
    .cover::before {
      content: "";
      position: absolute;
      right: -20mm;
      bottom: -25mm;
      width: 110mm;
      height: 110mm;
      border-radius: 50%;
      border: 1px solid rgba(255,255,255,0.09);
      background: radial-gradient(circle at 30% 30%, rgba(255,255,255,0.09), transparent 70%);
    }
    .eyebrow {
      display: inline-block;
      border: 1px solid rgba(255,255,255,0.3);
      border-radius: 999px;
      padding: 5px 12px;
      font-size: 11px;
      letter-spacing: .06em;
      text-transform: uppercase;
      color: var(--ink-dim);
    }
    h1 {
      font-size: 40px;
      line-height: 1.05;
      margin: 14px 0 8px;
      max-width: 520px;
    }
    .subtitle {
      color: #dee1e8;
      font-size: 20px;
      margin: 0 0 12px;
      font-weight: 600;
    }
    .meta {
      margin-top: 15mm;
      color: var(--ink-dim);
      font-size: 12px;
    }
    .meta-row { margin: 3px 0; }
    .divider {
      margin: 26px 0 14px;
      border: 0;
      border-top: 1px solid var(--line);
    }
    .page {
      page-break-before: always;
      padding-top: 6mm;
    }
    .doc {
      color: #1a1f28;
      font-size: 12.7px;
    }
    .doc h1, .doc h2, .doc h3, .doc h4 {
      color: #0d1421;
      margin: 1.1em 0 0.4em;
      line-height: 1.2;
    }
    .doc h1 { font-size: 26px; }
    .doc h2 {
      font-size: 20px;
      border-bottom: 1px solid #e4e8ef;
      padding-bottom: 6px;
    }
    .doc h3 { font-size: 16px; }
    .doc p { margin: .45em 0 .75em; }
    .doc ul, .doc ol { padding-left: 22px; }
    .doc li { margin: 4px 0; }
    .doc code {
      background: #f3f5f9;
      border: 1px solid #e1e6ef;
      border-radius: 6px;
      padding: 1px 5px;
      font-size: 11px;
    }
    .doc pre {
      background: #10131a;
      color: #eef2ff;
      border-radius: 10px;
      padding: 14px;
      overflow-x: auto;
      border: 1px solid #242b3a;
    }
    .doc pre code {
      background: transparent;
      border: 0;
      color: inherit;
      padding: 0;
    }
    .doc blockquote {
      margin: 0.9em 0;
      border-left: 4px solid var(--accent);
      padding: 4px 12px;
      color: #374151;
      background: #f9fbff;
      border-radius: 0 8px 8px 0;
    }
    .doc table {
      width: 100%;
      border-collapse: collapse;
      margin: 10px 0 14px;
      font-size: 11.2px;
      table-layout: fixed;
      overflow-wrap: anywhere;
    }
    .doc th, .doc td {
      border: 1px solid #d9dfeb;
      padding: 7px 8px;
      vertical-align: top;
      text-align: left;
    }
    .doc th {
      background: #f2f5fb;
      color: #111827;
    }
    .palette {
      margin-top: 14px;
      background: #f8f9fd;
      border: 1px solid #e4e8f2;
      border-radius: 12px;
      padding: 12px;
    }
    .palette h2 {
      margin: 0 0 8px;
      font-size: 15px;
      border: 0;
      padding: 0;
    }
    .swatch-grid {
      display: grid;
      grid-template-columns: repeat(7, minmax(0, 1fr));
      gap: 8px;
    }
    .swatch {
      border: 1px solid #dde3ef;
      border-radius: 8px;
      background: white;
      overflow: hidden;
    }
    .swatch-color {
      height: 22px;
      border-bottom: 1px solid rgba(0,0,0,0.08);
    }
    .swatch-label {
      padding: 5px 4px;
      text-align: center;
      font-size: 9px;
      color: #3e4a5f;
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    }
    .footer-note {
      margin-top: 8px;
      font-size: 10px;
      color: #6b7280;
    }
    .status-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #f2f9f4;
      color: #14532d;
      border: 1px solid #bee2c7;
      border-radius: 999px;
      padding: 4px 10px;
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: .03em;
      font-weight: 600;
    }
    .status-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--ok);
    }
  </style>
</head>
<body>
  <section class="cover">
    <div class="eyebrow">Mube Documentation Kit</div>
    <h1>$Title</h1>
    <p class="subtitle">$Subtitle</p>
    <div class="status-pill"><span class="status-dot"></span> Presentation Ready</div>
    <div class="meta">
      <div class="meta-row"><strong>Generated:</strong> $GeneratedAt</div>
      <div class="meta-row"><strong>Source:</strong> $SourceLabel</div>
    </div>
    <hr class="divider" />
    <p class="footer-note">This PDF is generated from markdown source with style-preserving print rendering.</p>
  </section>

  <main class="page doc">
    $ColorGridHtml
    $BodyHtml
  </main>
</body>
</html>
"@
}

function Convert-HtmlToPdf {
  param(
    [Parameter(Mandatory = $true)][string]$BrowserExe,
    [Parameter(Mandatory = $true)][string]$HtmlPath,
    [Parameter(Mandatory = $true)][string]$PdfPath
  )
  $absHtml = (Resolve-Path $HtmlPath).Path
  $uri = [Uri]::new($absHtml).AbsoluteUri
  $null = & $BrowserExe `
    '--headless=new' `
    '--disable-logging' `
    '--log-level=3' `
    '--disable-gpu' `
    '--run-all-compositor-stages-before-draw' `
    "--print-to-pdf=$PdfPath" `
    $uri
  if ($LASTEXITCODE -ne 0) {
    throw "Browser PDF render failed for: $PdfPath"
  }
  $found = $false
  for ($i = 0; $i -lt 60; $i++) {
    if (Test-Path $PdfPath) {
      $size = (Get-Item $PdfPath).Length
      if ($size -gt 0) {
        $found = $true
        break
      }
    }
    Start-Sleep -Milliseconds 250
  }
  if (-not $found) {
    throw "PDF output not found: $PdfPath"
  }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tmpDir = Join-Path $root 'tmp\pdfs'
$outDir = Join-Path $root 'output\pdf'
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$browser = Resolve-BrowserExe

$docs = @(
  @{
    Title = 'Mube Design System'
    Subtitle = 'Current Specification'
    Source = Join-Path $root 'design-system.md'
    Html = Join-Path $tmpDir 'mube-design-system-source-of-truth.html'
    Pdf = Join-Path $outDir 'mube-design-system-source-of-truth.pdf'
  },
  @{
    Title = 'Mube Design System'
    Subtitle = 'Audit and Migration Plan'
    Source = Join-Path $root 'docs\design-system-audit-2026-02-09.md'
    Html = Join-Path $tmpDir 'mube-design-system-audit-2026-02-09.html'
    Pdf = Join-Path $outDir 'mube-design-system-audit-2026-02-09.pdf'
  }
)

foreach ($doc in $docs) {
  $rawMd = Get-Content -Raw -Encoding UTF8 $doc.Source
  $bodyHtml = Convert-MarkdownToHtmlFragment -MarkdownPath $doc.Source
  $paletteHtml = Get-ColorGridHtml -MarkdownText $rawMd
  $generatedAt = [DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss UTC')
  $sourceLabel = $doc.Source.Replace($root, '').TrimStart('\').Replace('\', '/')
  $fullHtml = New-DocumentHtml `
    -Title $doc.Title `
    -Subtitle $doc.Subtitle `
    -SourceLabel $sourceLabel `
    -GeneratedAt $generatedAt `
    -ColorGridHtml $paletteHtml `
    -BodyHtml $bodyHtml

  Set-Content -Path $doc.Html -Value $fullHtml -Encoding UTF8
  Convert-HtmlToPdf -BrowserExe $browser -HtmlPath $doc.Html -PdfPath $doc.Pdf

  if (-not $Quiet) {
    Write-Output "Generated: $($doc.Pdf.Replace($root + '\', '').Replace('\', '/'))"
  }
}
