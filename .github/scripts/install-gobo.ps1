$ErrorActionPreference = "Stop"

$architecture = switch ($env:RUNNER_ARCH) {
    "X64" { "x86_64" }
    "ARM64" { "arm64" }
    default { throw "Unsupported runner architecture: $env:RUNNER_ARCH" }
}

$headers = @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    "X-GitHub-Api-Version" = "2022-11-28"
}
$release = Invoke-RestMethod `
    -Headers $headers `
    -Uri "https://api.github.com/repos/gobo-eiffel/gobo/releases/tags/$env:GOBO_TAG"
$prefix = "gobo-windows-$architecture-"
$asset = $release.assets |
    Where-Object { $_.name.StartsWith($prefix) -and $_.name.EndsWith(".7z") } |
    Select-Object -First 1
if ($null -eq $asset) {
    throw "No Gobo asset found with prefix $prefix"
}

$archive = Join-Path $env:RUNNER_TEMP "gobo.7z"
$distribution = Join-Path $env:RUNNER_TEMP "gobo-distribution"
New-Item -ItemType Directory -Force -Path $distribution | Out-Null
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive
& 7z x $archive "-o$distribution" -y | Out-Null
if ($LASTEXITCODE -ne 0) { throw "7z extraction failed" }

$gec = Get-ChildItem -Path $distribution -Recurse -File |
    Where-Object { $_.Directory.Name -eq "bin" -and $_.BaseName -eq "gec" } |
    Select-Object -First 1
if ($null -eq $gec) {
    throw "The Gobo archive does not contain bin/gec"
}

$goboRoot = $gec.Directory.Parent.FullName
"GOBO=$goboRoot" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
$gec.Directory.FullName | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
