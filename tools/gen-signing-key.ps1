# Generate an Ed25519 key pair for language-pack signing.
#
# Usage:
#   .\tools\gen-signing-key.ps1 -KeyId l10n-k1
#   .\tools\gen-signing-key.ps1 -KeyId l10n-k2 -OutDir C:\secure\l10n-keys
#
# Private keys are written outside the repo by default (~/.scomm/l10n-signing-keys).

param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[a-z][a-z0-9-]{1,31}$')]
  [string] $KeyId,

  [string] $OutDir = (Join-Path $env:USERPROFILE '.scomm' 'l10n-signing-keys')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
  throw 'OpenSSL not found on PATH. Install OpenSSL 3.x and retry.'
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$privatePath = Join-Path $OutDir "$KeyId-private.pem"
$publicPath = Join-Path $OutDir "$KeyId-public.pem"

if (Test-Path $privatePath) {
  throw "Refusing to overwrite existing private key: $privatePath"
}

& openssl genpkey -algorithm ED25519 -out $privatePath
& openssl pkey -in $privatePath -pubout -out $publicPath

$secretName = 'L10N_SIGNING_PRIVATE_KEY_' + ($KeyId.ToUpper() -replace '-', '_')
$assetName = "assets/l10n_pack_signing_${KeyId}_public.pem"

Write-Host ''
Write-Host "Key id:        $KeyId"
Write-Host "Private key:   $privatePath"
Write-Host "Public key:    $publicPath"
Write-Host "GitHub secret: $secretName"
Write-Host "App asset:     $assetName"
Write-Host ''
Write-Host 'Next steps:'
Write-Host "  1. Add secret $secretName to scomm-public/localizations (full private PEM)."
Write-Host "  2. Copy public PEM to secMail0/$assetName"
Write-Host "  3. Register key id in LanguagePackSigningKeys.trustedPublicKeyAssets"
Write-Host ''
