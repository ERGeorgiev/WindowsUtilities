#Requires -Version 7

Write-Host "Testing connection..."

Do
{
	$conn = Test-Connection -TargetName 8.8.8.8 -IPv4 -Count 1
	$lat = $conn.Latency
	$status = $conn.Status
	if ($status -ne 'Success') {
		$date = Get-Date
		Write-Host "[$date] Unsuccessful ping ($status)"
	}
	elseif ($lat -gt 100) {
		$date = Get-Date
		Write-Host "[$date] High latency ($lat)"
	}
	Sleep 1
} While ($true)