# 命令行构建脚本（无需打开 DevEco Studio）
# 用法：右键「使用 PowerShell 运行」，或在仓库根目录执行：
#   powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1

$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent

# 自动探测 DevEco Studio 安装目录
$candidates = @(
    'D:\dev\DevEco Studio',
    'C:\Program Files\Huawei\DevEco Studio',
    "$env:LOCALAPPDATA\Huawei\DevEco Studio"
)
$deveco = $candidates | Where-Object { Test-Path (Join-Path $_ 'tools\hvigor\bin\hvigorw.js') } | Select-Object -First 1
if (-not $deveco) {
    throw '未找到 DevEco Studio，请修改脚本顶部的 $candidates 路径'
}

$node = Join-Path $deveco 'tools\node\node.exe'
$hvigor = Join-Path $deveco 'tools\hvigor\bin\hvigorw.js'

$env:DEVECO_SDK_HOME = Join-Path $deveco 'sdk'
$env:JAVA_HOME = Join-Path $deveco 'jbr'
$env:Path = (Join-Path $deveco 'tools\node') + ';' + (Join-Path $deveco 'jbr\bin') + ';' + $env:Path

Write-Host "DevEco: $deveco"
Write-Host '开始构建 HAP...'
& $node $hvigor assembleHap --no-daemon
if ($LASTEXITCODE -ne 0) {
    throw "构建失败，退出码 $LASTEXITCODE"
}
Write-Host '构建成功，产物位于 entry/build/default/outputs/default/' -ForegroundColor Green
