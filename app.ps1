param([Parameter(Mandatory=$true, Position=0)][string] $InputPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Get-Dimension($value) {
    if ($null -eq $value -or $value -is [string] -or $value -is [bool] -or $value -is [array]) {
        throw 'Dimensions must be numbers'
    }
    return [decimal]$value
}
function Invoke-Analysis($data) {
    foreach ($key in 'frame','print') {
        if ($data[$key] -isnot [array] -or $data[$key].Count -ne 2) { throw 'Supply width and height for frame and print' }
    }
    $fw, $fh = $data.frame | ForEach-Object { Get-Dimension $_ }
    $pw, $ph = $data.print | ForEach-Object { Get-Dimension $_ }
    $overlap = Get-Dimension $data['overlap']
    $extra = Get-Dimension $data['extra_bottom']
    $w = $pw - 2 * $overlap
    $h = $ph - 2 * $overlap
    $side = ($fw - $w) / 2
    $top = ($fh - $h - $extra) / 2
    if ($overlap -lt 0 -or $extra -lt 0 -or $w -le 0 -or $h -le 0 -or $side -lt 0 -or $top -lt 0) {
        throw 'No opening fits these dimensions'
    }
    return [ordered]@{ opening=@($w,$h); borders=[ordered]@{left=$side;right=$side;top=$top;bottom=$top+$extra};
        corners=@(@($side,$top),@(($side+$w),($top+$h))) }
}

try {
    $payload = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json -AsHashtable
    if ($payload -isnot [System.Collections.IDictionary]) { throw 'Input must be a JSON object' }
    Invoke-Analysis $payload | ConvertTo-Json -Depth 30 -Compress
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
