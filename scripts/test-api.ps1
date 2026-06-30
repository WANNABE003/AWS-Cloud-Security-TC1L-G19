param(
  [string]$BaseUrl = "http://localhost:3000"
)

$ErrorActionPreference = "Stop"
if ($BaseUrl.StartsWith("https://")) {
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

function Invoke-JsonRequest {
  param(
    [string]$Method,
    [string]$Uri,
    [object]$Body,
    [Microsoft.PowerShell.Commands.WebRequestSession]$Session
  )

  $parameters = @{
    Method      = $Method
    Uri         = $Uri
    ContentType = "application/json"
  }
  if ($null -ne $Body) { $parameters.Body = ($Body | ConvertTo-Json -Depth 5) }
  if ($null -ne $Session) { $parameters.WebSession = $Session }
  Invoke-RestMethod @parameters
}

Write-Host "[1/5] Health endpoint"
$health = Invoke-JsonRequest GET "$BaseUrl/health" $null $null
if (-not $health.ok) { throw "Health check did not return ok=true" }

Write-Host "[2/5] Product database query"
$products = Invoke-JsonRequest GET "$BaseUrl/api/products" $null $null
if ($products.products.Count -lt 1) { throw "Seed products were not returned" }

Write-Host "[3/5] Customer authentication"
$customerSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$login = Invoke-JsonRequest POST "$BaseUrl/api/auth/login" @{
  email = "customer@securecart.local"
  password = "Password@123"
} $customerSession
if ($login.user.role -ne "Customer") { throw "Customer login failed" }

Write-Host "[4/5] Authenticated order query"
$orders = Invoke-JsonRequest GET "$BaseUrl/api/orders" $null $customerSession
if ($null -eq $orders.orders) { throw "Order API returned no collection" }

Write-Host "[5/5] SQL-injection-shaped login is rejected"
try {
  Invoke-JsonRequest POST "$BaseUrl/api/auth/login" @{
    email = "admin@securecart.local' OR '1'='1"
    password = "Password@123"
  } $null | Out-Null
  throw "Injection-shaped request was unexpectedly accepted"
} catch {
  $status = [int]$_.Exception.Response.StatusCode
  if ($status -notin @(400, 401, 403)) { throw }
}

Write-Host "PASS: health, PostgreSQL, login, RBAC session, and injection rejection all worked." -ForegroundColor Green
