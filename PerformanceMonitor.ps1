#Requires -Version 7
$previousProcesses = @{}
$initialized = $false
$period = 5

Write-Host "Performance Monitor" -BackgroundColor White -ForegroundColor Black
Write-Host "Every $period second(s), any started/stopped or high usage processes will be logged here."
$cpuThreads = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
$cpuSecondsPerDelay = $cpuThreads * $period
$cpuUsagePercentageThreshold = 5

Do
{
	$date = Get-Date
	$allProcesses = Get-Process
	
	# Combine same process names into the same value
	$currentProcesses = @{}
	Foreach ($p in $allProcesses) {
		if ($currentProcesses.Keys -contains $p.Name) {
			$currentProcesses[$p.Name] += $p.CPU
		}
		else {
			$currentProcesses[$p.Name] = $p.CPU
		}
	}
	
	# Get any stopped processes
	Foreach ($p in $previousProcesses.GetEnumerator()) {
		$name = $p.Key
		if (($currentProcesses.Keys -contains $name) -eq $false) {
			Write-Host "[$date] Process Stopped: $name" -ForegroundColor Red
		}
	}
	
	# Get any outliers and started processes
	$spikingProcesses = @{}
	Foreach ($p in $currentProcesses.GetEnumerator()) {
		$name = $p.Key
		$current = $currentProcesses[$name]
		if ($previousProcesses.Keys -contains $name) {
			$change = $current - $previousProcesses[$name]
			$usage = ($change / $cpuSecondsPerDelay) * 100
			if ($usage -gt $cpuUsagePercentageThreshold) {
				$usage = [Math]::Min($usage, 100)
				$spikingProcesses[$name] = [Int]$usage
			}
		}
		else {
			if ($initialized) {
				Write-Host "[$date] Process Started: $name" -ForegroundColor Green
			}
		}
	}

	# Print outliers
	Foreach ($p in $spikingProcesses.GetEnumerator()) {
		$name = $p.Key
		$usage = $p.Value
		Write-Host "[$date] High CPU Usage: $name ($usage%)"
	}
	
	$previousProcesses = $currentProcesses
	$initialized = $true
	
	Start-Sleep $period
} While ($true)