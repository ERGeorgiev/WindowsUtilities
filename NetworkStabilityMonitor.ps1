#Requires -Version 7

Write-Host "Testing connection..."

$netRoute = Get-NetRoute |
	Where {$_.DestinationPrefix -eq '0.0.0.0/0'}
$router = $netRoute.NextHop[0]
$google = '8.8.8.8'
$cloudflare = '1.1.1.1'

Write-Host "Router: $router"
Write-Host "Monitoring: $google"
Write-Host "Monitoring: $cloudflare"

$init = {
	Function Monitor-Connection {
		Param ([String]$name, [String]$ip)
		$conn = Test-Connection -TargetName $ip -IPv4 -Count 1
		$lat = $conn.Latency
		$status = $conn.Status
		if ($status -ne 'Success') {
			$date = Get-Date
			Write-Host "[$date] Unsuccessful ping for '$name' ($status)"
		}
		elseif ($lat -gt 100) {
			$date = Get-Date
			Write-Host "[$date] High latency for '$name' ($lat)"
		}
	}
}

Do {
	$conn = Test-Connection -TargetName $router -IPv4 -Count 1
	$lat = $conn.Latency
	$status = $conn.Status
	if ($status -ne 'Success') {
		$date = Get-Date
		Write-Warning "[$date] Unable to reach router ($status)"
	}
	elseif ($lat -gt 100) {
		$date = Get-Date
		Write-Warning "[$date] High latency for router ($lat)"
	}
	else {
		Start-Job -InitializationScript $init -ScriptBlock{Monitor-Connection "Google" $args[0]} -ArgumentList $google | Out-Null
		Start-Job -InitializationScript $init -ScriptBlock{Monitor-Connection "CloudFlare" $args[0]} -ArgumentList $cloudflare | Out-Null
		Get-Job | Wait-Job | Out-Null
		Get-Job | Receive-Job
		Get-Job | Remove-Job
	}
	
	Sleep 1
} While ($true)