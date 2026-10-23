# WinCC Unified Trace Web - local-only HTTP server. Windows PowerShell 5.1+
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile = Join-Path $root 'settings.json'
$stdoutFile = Join-Path $root 'receiver-out.log'
$stderrFile = Join-Path $root 'receiver-error.log'
$script:receiver = $null
$defaultBin = 'C:\Program Files\Siemens\Automation\WinCCUnified\bin'
$script:config = @{ ip='192.168.1.100'; bin=$defaultBin }
if (Test-Path $configFile) {
  try { $loaded = Get-Content $configFile -Raw | ConvertFrom-Json; foreach($key in @('ip','bin')) { if ($null -ne $loaded.$key) { $script:config[$key] = [string]$loaded.$key } } } catch {}
}
function Reply($ctx, $obj, [int]$code=200) {
  $json = ConvertTo-Json -InputObject $obj -Compress -Depth 4
  $bytes = [Text.Encoding]::UTF8.GetBytes($json)
  $ctx.Response.StatusCode = $code
  $ctx.Response.ContentType = 'application/json; charset=utf-8'
  $ctx.Response.ContentLength64 = $bytes.Length
  $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
  $ctx.Response.Close()
}
function ReadBody($req) {
  $reader = [IO.StreamReader]::new($req.InputStream,[Text.Encoding]::UTF8)
  try { return ($reader.ReadToEnd() | ConvertFrom-Json) } finally { $reader.Dispose() }
}
function ReadSharedLog([string]$path) {
  if (-not [IO.File]::Exists($path)) { return '' }
  $stream = $null
  $reader = $null
  try {
    $stream = [IO.FileStream]::new($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)
    $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8, $true)
    $content = $reader.ReadToEnd()
    if ($content.Length -gt 100000) { return $content.Substring($content.Length - 100000) }
    return $content
  } catch [IO.IOException] {
    # El registro puede estar rotando o iniciándose: no interrumpir el servidor HTTP.
    return ''
  } finally {
    if ($null -ne $reader) { $reader.Dispose() }
    elseif ($null -ne $stream) { $stream.Dispose() }
  }
}
function Running { return ($null -ne $script:receiver -and -not $script:receiver.HasExited) }
function StopReceiver {
  if ($null -eq $script:receiver) { return @{ok=$true; stopped=$true; message='No hay receptor iniciado por esta aplicación'} }
  $pidToStop = [int]$script:receiver.Id
  if (-not (Running)) {
    $script:receiver.Dispose(); $script:receiver = $null
    return @{ok=$true; stopped=$true; pid=$pidToStop; message='El receptor ya había terminado'}
  }
  $tool = ToolPath
  $stopMessage = ''
  # Parada solicitada mediante el mecanismo que muestra RTILtraceTool.
  try {
    $stopProc = Start-Process -FilePath $tool -ArgumentList @('-mode','stop','-process',"$pidToStop") -PassThru -WindowStyle Hidden
    if (-not $stopProc.WaitForExit(5000)) {
      try { $stopProc.Kill() } catch {}
      $stopMessage = 'El comando de parada no terminó en 5 segundos.'
    }
    $stopProc.Dispose()
  } catch { $stopMessage = 'Error al solicitar la parada: ' + $_.Exception.Message }
  # Confirmar terminación del PID exacto antes de mostrar receptor detenido.
  if (-not $script:receiver.WaitForExit(5000)) {
    return @{ok=$false; stopped=$false; pid=$pidToStop; error=('El receptor PID ' + $pidToStop + ' sigue activo. ' + $stopMessage)}
  }
  $script:receiver.Dispose(); $script:receiver = $null
  return @{ok=$true; stopped=$true; pid=$pidToStop; message='Receptor detenido y PID verificado'}
}
function SaveConfig { $script:config | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8 }
function ToolPath { return (Join-Path $script:config.bin 'RTILtraceTool.exe') }
function ViewerPath { return (Join-Path $script:config.bin 'RTILtraceViewer.exe') }
function ValidIp($ip) {
  $parsed = $null
  return ([Net.IPAddress]::TryParse($ip,[ref]$parsed) -and $parsed.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork)
}
$listener = New-Object Net.HttpListener
$listener.Prefixes.Add('http://localhost:8080/')
try { $listener.Start() } catch { Write-Host "No se pudo abrir http://localhost:8080 : $_"; exit 1 }
Write-Host 'Servidor disponible: http://localhost:8080'
Start-Process 'http://localhost:8080'
try {
 while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
   $path = $ctx.Request.Url.AbsolutePath
   $method = $ctx.Request.HttpMethod
   if ($path -eq '/' -and $method -eq 'GET') {
    $bytes = [IO.File]::ReadAllBytes((Join-Path $root 'index.html'))
    $ctx.Response.ContentType = 'text/html; charset=utf-8'
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    $ctx.Response.Close()
   } elseif ($path -eq '/api/status' -and $method -eq 'GET') {
    Reply $ctx @{running=(Running); ip=$script:config.ip; bin=$script:config.bin}
   } elseif ($path -eq '/api/save' -and $method -eq 'POST') {
    $body = ReadBody $ctx.Request
    if (-not (ValidIp ([string]$body.ip))) { throw 'IP IPv4 no válida' }
    $script:config.ip = [string]$body.ip
    if (-not [string]::IsNullOrWhiteSpace([string]$body.bin)) { $script:config.bin = [string]$body.bin }
    SaveConfig
    Reply $ctx @{ok=$true}
   } elseif ($path -eq '/api/start' -and $method -eq 'POST') {
    if (Running) { throw 'El receptor ya está ejecutándose' }
    $body = ReadBody $ctx.Request
    $ip = [string]$body.ip
    if (-not [string]::IsNullOrWhiteSpace([string]$body.bin)) { $script:config.bin = [string]$body.bin }
    $tool = ToolPath
    if (-not (ValidIp $ip)) { throw 'IP IPv4 no válida' }
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) { throw 'No se encuentra RTILtraceTool.exe. Indica su ruta completa.' }
    if ([IO.Path]::GetFileName($tool) -ine 'RTILtraceTool.exe') { throw 'Selecciona RTILtraceTool.exe' }
    $script:config.ip = $ip; SaveConfig
    Set-Content -Path $stdoutFile -Value '' -Encoding UTF8
    Set-Content -Path $stderrFile -Value '' -Encoding UTF8
    $script:receiver = Start-Process -FilePath $tool -ArgumentList @('-mode','receiver','-host',$ip,'-tcp') -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
    Reply $ctx @{ok=$true; pid=$script:receiver.Id}
   } elseif ($path -eq '/api/stop' -and $method -eq 'POST') {
    $result = StopReceiver
    if (-not $result.ok) { Reply $ctx $result 409 } else { Reply $ctx $result }
   } elseif ($path -eq '/api/viewer' -and $method -eq 'POST') {
    $body = ReadBody $ctx.Request
    if (-not [string]::IsNullOrWhiteSpace([string]$body.bin)) { $script:config.bin = [string]$body.bin }
    $viewer = ViewerPath
    if (-not (Test-Path -LiteralPath $viewer -PathType Leaf)) { throw 'No se encuentra RTILtraceViewer.exe' }
    if ([IO.Path]::GetFileName($viewer) -ine 'RTILtraceViewer.exe') { throw 'Selecciona RTILtraceViewer.exe' }
    SaveConfig
    Start-Process -FilePath $viewer | Out-Null
    Reply $ctx @{ok=$true}
   } elseif ($path -eq '/api/log' -and $method -eq 'GET') {
    $out = ReadSharedLog $stdoutFile
    $err = ReadSharedLog $stderrFile
    Reply $ctx @{stdout=$out; stderr=$err; running=(Running)}
   } else { Reply $ctx @{error='Ruta no encontrada'} 404 }
  } catch { try { Reply $ctx @{error=$_.Exception.Message} 400 } catch {} }
 }
} finally {
 if (Running) { try { $null = StopReceiver } catch {} }
 $listener.Stop(); $listener.Close()
}
