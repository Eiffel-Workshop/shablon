$ErrorActionPreference = "Stop"

$version = $env:EIFFELSTUDIO_VERSION
$revision = $env:EIFFELSTUDIO_REVISION
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "EIFFELSTUDIO_VERSION is required"
}
if ([string]::IsNullOrWhiteSpace($revision)) {
    throw "EIFFELSTUDIO_REVISION is required"
}
if ($env:RUNNER_ARCH -ne "X64") {
    throw "Unsupported runner architecture: $env:RUNNER_ARCH"
}

$platform = "win64"
$archiveName = "Eiffel_${version}_rev_${revision}-${platform}.7z"
$archiveUrl = "https://www.eiffel.com/cdn/EiffelStudio/$version/$revision/$archiveName"
$archive = Join-Path $env:RUNNER_TEMP $archiveName
$distribution = Join-Path $env:RUNNER_TEMP "eiffelstudio-distribution"
$root = Join-Path $distribution "Eiffel_$version"
$compiler = Join-Path $root "studio\spec\$platform\bin\ec.exe"

New-Item -ItemType Directory -Force -Path $distribution | Out-Null
curl.exe -fsSL -o $archive $archiveUrl
if ($LASTEXITCODE -ne 0) { throw "Cannot download $archiveUrl" }

$sevenZip = (Get-Command 7z.exe -ErrorAction Stop).Source
& $sevenZip x $archive "-o$distribution" -y | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Cannot extract $archive" }

if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw "The EiffelStudio archive does not contain $compiler"
}

$compilerDirectory = Split-Path -Parent $compiler
$env:ISE_EIFFEL = $root
$env:ISE_LIBRARY = $root
$env:ISE_PLATFORM = $platform
$env:ISE_C_COMPILER = "msc_vc140"
$env:PATH = "$compilerDirectory;$env:PATH"
& $compiler -version
if ($LASTEXITCODE -ne 0) { throw "The EiffelStudio compiler cannot start" }

"ISE_EIFFEL=$root" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
"ISE_LIBRARY=$root" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
"ISE_PLATFORM=$platform" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
"ISE_C_COMPILER=$env:ISE_C_COMPILER" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
$compilerDirectory | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
