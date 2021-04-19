#Requires -Version 7

Write-Host "Monitoring CPU..."

Do
{
	$countersGrouped = (Get-Counter '\Process(*)\% Processor Time' 2>&1).CounterSamples | Group-Object -Property InstanceName
	$counters = @{}
	$countersGrouped | ForEach-Object -Process {$counters += @{$_.name = ($_.Group | Measure-Object -Sum {$_.CookedValue}).Sum}}
	$idle = $counters["idle"]
	$total = $counters["_total"]
	$used = $total - $idle
	$usedPct = ($used / $total) * 100
	if ($usedPct -gt 50) {
		$usedPct = [Math]::Round($usedPct, 2)
		$date = Get-Date
		
		$counters = $counters.GetEnumerator() | Where-Object {$_.Key -ne "idle" -and $_.Key -ne "_total"}
		$top = $counters | Sort-Object -Property Value -Descending | Select-Object -First 3
		[Array]$topArray = @()
		Foreach ($t in $top) {
			$val = ($t.Value / $total) * 100
			$val = [Math]::Round($val, 2)
			$name = $t.Name
			$topArray += "$name[$val%]"
		}
		$topString = $topArray -Join ', '
		
		Write-Host "[$date] High CPU usage: $usedPct% ($topString)"
	}
	Sleep 5
} While ($true)