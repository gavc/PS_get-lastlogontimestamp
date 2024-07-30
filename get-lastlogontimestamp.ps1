# Import the Active Directory module
Import-Module ActiveDirectory

$logFilePath = "C:\temp\logs\$(Get-Date -Format 'yyyyMMddHHmmss')_get-lastlogontimestamp.txt"

# Write a simple log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Message,

        [Parameter(Mandatory=$false)]
        [string] $Path = $logFilePath
    )

    # Get the current date and time
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Format the log entry
    $logEntry = "$timestamp - $Message"

    # Append the log entry to the file
    Add-Content -Path $Path -Value $logEntry
}

# Define the domains
$domains = @("domain1", "domain2")

# Read the PC names from the file
$pcNames = Get-Content -Path "C:\temp\scripts\pcs.txt"

# Get the credentials for the second domain
$credential = Get-Credential -Message "Please enter your credentials for $($domains[1])"

foreach ($pc in $pcNames) {
    $lastLogonTimestamps = @{}

    foreach ($domain in $domains) {
        try {
            # Get the computer information from the domain
            if ($domain -eq $domains[0]) {
                $computer = Get-ADComputer -Identity $pc -Server $domain -Properties lastLogonTimestamp -ErrorAction Stop

                Write-Log -Message "$pc $domain - $computer"
            }
            else {
                $computer = Get-ADComputer -Identity $pc -Server $domain -Credential $credential -Properties lastLogonTimestamp -ErrorAction Stop

                Write-Log -Message "$pc $domain - $computer"
            }

            # Add the LastLogonTimestamp to the list
            $lastLogonTimestamps[$domain] = $computer.lastLogonTimestamp
        }
        catch {
            #Write-Output "Error retrieving information for $pc in $domain $_"
        }
    }

    if ($lastLogonTimestamps.Count -gt 0) {
        # Get the latest logon timestamp and the corresponding domain
        $latestLogon = $lastLogonTimestamps.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

        # Convert the timestamp to a DateTime object
        $lastLogonDate = [DateTime]::FromFileTime($latestLogon.Value)

        # Format the date
        $formattedDate = $lastLogonDate.ToString("dd/MM/yyyy HH:mm:ss")

        Write-Log -Message "$pc $formattedDate from $($latestLogon.Name) lastLogonTimestamp"

        Write-Output "$pc $formattedDate from $($latestLogon.Name) lastLogonTimestamp"
    }
    else {
        Write-Output "$pc notfound"
    }
}
$credential = $null
