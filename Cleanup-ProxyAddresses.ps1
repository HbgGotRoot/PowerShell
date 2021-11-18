$DC = Read-Host "PDC or whichever DC is the master for the domain"
$Domain = Read-Host "Domain(s) you want to search for and remove from ProxyAddresses. Separate multiple domains with a comma"
$Debug = Read-Host "Do you want to test with a small group first (Y/N)"


IF ($DC -eq ''){
	$Controllers = Get-DomainController
	
	IF ($Controllers.Count -gt 1){
		$DC = $Controllers[0].DnsHostName
	} ELSE {
		$DC = $Controllers.DnsHostName
	}
}

IF ($Domain -eq ''){
	"At least one domain name is required."
	Break;
}

IF ($Debug -AND $Debug -eq 'Y'){
	$Results = Read-Host "How many user(s) to check?"
	
	IF ($Results){
		IF ($Domain.contains(',')){
			$Domains = $Domain.split(',') # Handler for multiple domains entered. Could add .split(' ') to expand option to space serarated values. But recommend sticking to commas.
			
			$Domain = $Domains[0].Trim() # Trim off any leading or trailing spaces.
			$Domain = "*@$($Domain)" # Build the wildcard address to search for.
			
			$Users = get-aduser -Filter {ProxyAddresses -like $Domain} -Server $DC -ResultSetSize $Results -Properties * | Sort SamAccountName;
		} ELSE {
			$Domain = $Domain.Trim()
			
			$Users = get-aduser -Filter {ProxyAddresses -like $Domain} -Server $DC -ResultSetSize $Results -Properties * | Sort SamAccountName;
		}	
		# Returns just the $Domain address if it is present in ProxyAddresses
		FOREACH($Address in $Users.ProxyAddresses){
			IF ($Address -like $Domain){
				$Address
			};
		}
	} ELSE {
		"A number is required."
		Break;
	}
} ELSE {
	IF ($Domain.contains(',')){
		$Domains = $Domain.split(',') # Handler for multiple domains entered. Could add .split(' ') to expand option to space serarated values. But recommend sticking to commas.
		
		FOREACH($Domain in $Domains){
			$Domain = $Domain.Trim()
			
			$Domain = "*@$($Domain)" # Build the wildcard address to search for.
			
			$Users = get-aduser -Filter {ProxyAddresses -like $Domain} -Server $DC -Properties * | Sort SamAccountName;
			FOREACH($User in $Users){
				$Identity = $User.SamAccountName; # Needed this because the MailNickname isn't always the same as the accounts SamAccountName
				$MailAlias = $User.MailNickname;
				FOREACH($Address in $Users.ProxyAddresses){
					IF ($Address -like $Domain){
						Set-ADUser -Identity $Identity -Server $DC -remove @{ProxyAddresses=$Address};
					};
				}
			};
		};
	} ELSE {
		$Domain = $Domain.Trim() # Trim off any leading or trailing spaces.
		
		$Users = get-aduser -Filter {ProxyAddresses -like $Domain} -Server $DC -Properties * | Sort SamAccountName;
		FOREACH($User in $Users){
			$Identity = $User.SamAccountName; # Needed this because the MailNickname isn't always the same as the accounts SamAccountName
			$MailAlias = $User.MailNickname;
			FOREACH($Address in $Users.ProxyAddresses){
				IF ($Address -like $Domain){
					Set-ADUser -Identity $Identity -Server $DC -remove @{ProxyAddresses=$Address};
				};
			}
		};
	}
};