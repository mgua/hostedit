# this windows powershell file updates hosts file
# with local wsl current ip address
# allowing easy integration with locally provided
# apps in development machines
#
# mgua@tomware.it
# mar 2022
#
#
##################

$HostsFile = 'C:\Windows\System32\drivers\etc\hosts'
$NewHostsFile = 'C:\Windows\System32\drivers\etc\newhosts'

$wsl_name = 'kali-linux'
$names = @("kali", "mykali", "kalihost", "mgkali", "mgk")
$wsl_ip = (wsl -d $wsl_name hostname -I).trim() 
echo wsl_ip:$wsl_ip

# will search $names strings in hostfile, and replace each line with
# $wsl_ip $names

if (-not(Test-Path -Path $HostsFile -PathType Leaf)) {
	Write-Host "FATAL: file $HostsFile not found."
	Exit 222
}

if (Test-Path -Path $NewHostsFile -PathType Leaf) {
	Write-Host "FATAL: $NewHostsFile already exist. Please delete."
	Exit 223
}

$stream_reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $HostsFile
$stream_writer = New-Object -TypeName System.IO.StreamWriter -ArgumentList $NewHostsFile

while (($line =$stream_reader.ReadLine()) -ne $null){
	$found = $FALSE
	foreach ($name in $names) {
		# check if $name appears as a word
        if ($line -cmatch "\W" + $name) {
			$found = $TRUE
		}
	}
	if (-not $found) {
		$stream_writer.WriteLine($line)					
		}
}


foreach ($name in $names) {
	$stream_writer.WriteLine($wsl_ip + " " + $name)			
}


$stream_writer.close()
$stream_reader.close()

$dateFormat = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
$HostsFileBak = $HostsFile + '_' + $dateFormat  + '.backup'
Remove-Item -path $HostsFileBak >$null 2>&1
Move-Item -path $HostsFile -Destination $HostsFileBak
Move-Item -path $NewHostsFile -Destination $HostsFile
Write-Host "Hosts file [$HostsFile] updated with:"
foreach ($name in $names) {
	Write-Host "  $wsl_ip $name"			
}


#
# you can send commands to your wsl with the name of the wsl
# c:\kali.exe -c "ip address list | grep eth0 | grep inet"
# c:\kali.exe -c "ip address list | grep 'scope global eth0'"
# c:\wsl ip a l eth0
# wsl -d "kali-linux" hostname -I
#

# this binds the specified tcp ports on the localhost
#netsh interface portproxy add v4tov4 listenport=22 connectport=22 connectaddress=$wsl_ip
#netsh interface portproxy add v4tov4 listenport=80 connectport=80 connectaddress=$wsl_ip
#netsh interface portproxy add v4tov4 listenport=443 connectport=443 connectaddress=$wsl_ip

 
