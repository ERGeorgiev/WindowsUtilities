#Requires -Version 7

Write-Host "Testing connection..."

$netRoute = Get-NetRoute |
	Where {$_.DestinationPrefix -eq '0.0.0.0/0'}
$router = $netRoute.NextHop[0]
$google = '8.8.8.8'

Write-Host "Monitoring: $router"
Write-Host "Monitoring: $google"

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

Do
{
	Start-Job -InitializationScript $init -Name "MonitorGoogle" -ScriptBlock{Monitor-Connection "Google" $args[0]} -ArgumentList $google | Out-Null
	Start-Job -InitializationScript $init -Name "MonitorGoogle" -ScriptBlock{Monitor-Connection "Router" $args[0]} -ArgumentList $router | Out-Null
	Get-Job | Wait-Job | Out-Null
	Get-Job | Receive-Job
	Get-Job | Remove-Job
	Sleep 1
} While ($true)