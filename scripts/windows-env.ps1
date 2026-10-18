# Use the project-local compatible toolchain, if prepared. No download or login.
$taskMoonRoot = Join-Path $PSScriptRoot '..\release-local\toolchain'
if (!(Test-Path -LiteralPath (Join-Path $taskMoonRoot 'bin\moon.exe'))) {
  throw 'Prepare the documented compatible MoonBit toolchain first.'
}
$env:MOON_HOME = (Resolve-Path -LiteralPath $taskMoonRoot).Path
$env:PATH = "$env:MOON_HOME\bin;$env:PATH"
