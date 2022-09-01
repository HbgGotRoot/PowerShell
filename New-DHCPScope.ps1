<#
    .SYNOPSIS
        Quickly creates DHCP scope(s) from a CSV file.

    .DESCRIPTION
        Create DHCP scope(s) from a CSV file. 
        
        File must contain the following column header values:
			Name
			Description
			StartRange
			EndRange
			SubnetMask
			LeaseDuration
			ScopeId (Scope subnet i.e 192.168.1.0)
			Gateway (Optional DHCP Scope Option 3 value)
				
		You can include Server, ExcludeRange and Delay in the CSV file. 
		These Parameters are optional from the command line, and allow the same CSV file to be applied to multiple DHCP servers with different exclusion ranges and delay values.
			
		The cmdlet takes the ScopeId from the CSV file and replaces the last octet with the values provided for ExcludeRange to create the Start and End range(s).

        There is a sub-routine in this cmdlet that checkes for existing DHCP scopes, and reports on any duplicates found once the CSV file has been processed.

    .PARAMETER File
        File to be used for creating DHCP scope(s)

    .PARAMETER Server
        FQDN or IP address of DHCP server/computer
            
    .PARAMETER ExcludeRange
		This can be a single exclude range or multiple exclude ranges. 
		Exclude range should be in the form of: beginning-ending 50-99. 
		For multiple exclude ranges, use quotes and separate each range with a space, i.e. "50-99 150-199"
			
	.PARAMETER Delay
		This is the value assigned to the DHCP scope for delay in issuing DHCP addresses.

    .PARAMETER Test
        This will turn on debugging. This is handy for checking to see what the script will do, before you commit to running the script.

    .NOTES
        Name: New-DHCPScope
        
        Created: August 2018
        Updated: September 2022


    .EXAMPLE
        New-DHCPScope -File DHCPScopes.csv -Server Anyserver.your.net -ExcludeRange 50-149 -Delay 0
            
        Description
        -----------
        Created new DHCP scope(s) on Anyserver.your.net with a DHCP exclude range of 50-149 and a 0 millisecond delay.
		For example, if the subnet for the scope is 192.168.1.0, then the exclude range would be 192.168.1.50-192.168.1.149

    .EXAMPLE
        New-DHCPScope -File DHCPScopes.csv -Server Anyserver.your.net -ExcludeRange "50-149 150-199" -Delay 0
            
        Description
        -----------
        Created new DHCP scope(s) on Anyserver.your.net with a DHCP multiple exclude ranges 50-149 and 150-199 and a 0 millisecond delay.
        For example, if the subnet for the scope is 192.168.1.0, then the exclude ranges would be 192.168.1.50-192.168.1.149 and 192.168.1.150-192.168.1.199


	.EXAMPLE
		New-DHCPScope -File DHCPScopes.csv -Server Anyserver.your.net
			
		Description
		-----------
		Created new DHCP scope(s) on Anyserver.your.net with default values for ExcludeRange and Delay or values included in the CSV file.

			
	.EXAMPLE
		New-DHCPScope -File DHCPScopes.csv
			
		Description
		-----------
		Create new DHCP scope(s) using values from the CSV file.
	
	.EXAMPLE
		New-DHCPScope -File DHCPScopes.csv -Test
		
		Description
		-----------
		Outputs the values from the CSV file and the string value of the ADD-DHCPServerv4Scope so that values can be confirmed prior to committing to run the script against your server.
		Sample output:
			====================================
			Server: Anyserver.your.net
			Scope Name: This is the scope name
			Scope Description: This is the scope description
			Scope Start: 169.254.0.0
			Scope end: 169.254.0.254
			Exclude Range: 20-30 100-149 200-240
			Subnet mask: 255.255.255.0
			Delay: 0
			Lease Duration: 21
			ScopeID: 169.254.0.0
			State: Active
			====================================
			Action: Add-DhcpServerv4Scope -ComputerName Anyserver.your.net -Name This is the scope name -Description This is the scope description -StartRange 169.254.0.0 -EndRange 169.254.0.254 -SubnetMask 255.255.255.0 -Delay 0 -LeaseDuration 21 -
			State Active
			====================================
#>

param(
	[parameter(Mandatory=$true)][String]$File,
	[parameter(Mandatory=$false)][String]$Server,
    [parameter(Mandatory=$false)][String]$ExcludeRange,
    [parameter(Mandatory=$false)][Int]$Delay,
	[parameter(Mandatory=$false)][String]$State,
	[Parameter(Mandatory=$False)][Switch]$Test
)

$Message = ""

$Debug = $Test

$Scopes = Import-CSV -Path $File

foreach($Scope in $Scopes){
	if ($Scope.DHCPServer) {
		$Server = $Scope.DHCPServer
	} elseif (-not $Server) {
        $Server = "localhost"
    }

    $Subnet = $Scope.ScopeID
	
	if ($Debug){
		"===================================="
		"Server: "+ $Server
		"Scope Name: "+ $Scope.Name
		"Scope Description: "+ $Scope.Description
		"Scope Start: "+ $Scope.StartRange
		"Scope end: "+ $Scope.EndRange
        "Exclude Range: $ExcludeRange"
		"Subnet mask: "+ $Scope.SubnetMask
		"Delay: "+ $Delay
		"Lease Duration: "+ $Scope.LeaseDuration
        "ScopeID: $Subnet"
		"State: $State"
		"===================================="
        $Action =  "Add-DhcpServerv4Scope -ComputerName $Server -Name " +$Scope.Name+ " -Description " +$Scope.Description+ " -StartRange " +$Scope.StartRange+ " -EndRange " +$Scope.EndRange+ " -SubnetMask " +$Scope.SubnetMask+ " -Delay $Delay -LeaseDuration " +$Scope.LeaseDuration+ " -State $State"
        "Action: $Action"
        "===================================="
	} else {
		if (-not (Get-DhcpServerv4Scope -ComputerName $Server | ? { $Scope.ScopeId -ne $Subnet})){

			Add-DhcpServerv4Scope -ComputerName $Server -Name $Scope.Name -Description $Scope.Description -StartRange $Scope.StartRange -EndRange $Scope.EndRange -SubnetMask $Scope.SubnetMask -Delay $Delay -LeaseDuration $Scope.LeaseDuration -State $State
		
			$Exclude = $ExcludeRange.split(" ")
			$Subnet = $Subnet.Substring(0, $Subnet.LastIndexOf("."))

			foreach ($i in $Exclude.split(" ")){
				$i = $i.split("-")
				for ($j = 0; $j -lt $i.Count; $j++){
					$StartExc = $subnet + "." + $i[$j]

					$j++

					$EndExc = $subnet + "." + $i[$j]

					Add-DhcpServerv4ExclusionRange -ComputerName $Server -ScopeId $Scope.ScopeID -StartRange $StartExc -EndRange $EndExc
					#$ExcRange = $StartExc + " " + $EndExc

					#$ExcRange
				}
			} 
			
			if ($Scope.Gateway){
				Set-DhcpServerv4OptionValue -ComputerName $Server -ScopeID $Scope.ScopeID -OptionId 3 $Scope.Gateway
			}
		} else {
			$Message = $Message + '===========================================================================================' + "`r`n"
			$Message = $Message + 'Attention! - A DHCP Scope with Scope ID: ' + $Scope.ScopeID + ' already exists on server: ' + $Server + "`r`n"
			$Message = $Message + 'This scope will not be added' + "`r`n"
			$Message = $Message + 'Scope Name: ' + $Scope.Name + "`r`n"
			$Message = $Message + 'Description: ' + $Scope.Description + "`r`n"
			$Message = $Message + 'Range: ' + $Scope.StartRange + '-' + $Scope.EndRange + "`r`n"
			$Message = $Message + '===========================================================================================' + "`r`n"
			$Message = $Message + "`r`n"
		}
	}
}

$Color = $host.ui.RawUI.ForegroundColor
$host.ui.RawUI.ForegroundColor = "Red"
Write-Output $Message
$host.ui.RawUI.ForegroundColor = $Color