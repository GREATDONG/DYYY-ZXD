# DYYY 推送脚本
# 使用方法: 右键 -> 使用 PowerShell 运行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DYYY 优化包推送到 GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$repoPath = "f:\GITHUB\QCLAW\dyyy_optimized"

# 检查路径
if (-not (Test-Path $repoPath)) {
    Write-Host "错误: 找不到仓库目录" -ForegroundColor Red
    Write-Host "路径: $repoPath" -ForegroundColor Red
    pause
    exit 1
}

# 切换到仓库目录
Set-Location $repoPath
Write-Host "当前目录: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# 推送
Write-Host "正在推送到 GitHub..." -ForegroundColor Yellow
Write-Host ""

try {
    git push origin master

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "推送成功!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "GitHub Actions 将自动构建 .deb 包" -ForegroundColor Cyan
        Write-Host "查看构建状态: https://github.com/GREATDONG/DYYY-ZXD/actions" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "推送失败 (错误码: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "请检查网络连接" -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "错误: $_" -ForegroundColor Red
}

Write-Host ""
pause
