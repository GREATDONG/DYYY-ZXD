$json = Get-Content "f:\GITHUB\QCLAW\dyyy_optimized\request.json" -Raw
$headers = @{"Authorization" = "Bearer sk-rdmybxbzcytpvqwkjzjepsclhhdxnqnkjbeywrkqieyoxmuw"; "Content-Type" = "application/json"}
$response = Invoke-WebRequest -Uri "https://api.siliconflow.cn/v1/chat/completions" -Method Post -Headers $headers -Body $json -UseBasicParsing -TimeoutSec 60
Write-Host $response.Content
