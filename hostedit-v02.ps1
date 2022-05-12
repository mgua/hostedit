# hostedit_v02.ps1
# this windows powershell file updates hosts file
# with local wsl current ip address
# allowing easy integration with locally provided
# apps in development machines
#
# march 20, 2022: added command chaining feature
# may 12, 2022: kstefan@tomware.it added detection of multiple 
#				ip on wsl machine
#               (it selects the last one)
#
#
# Marco Guardigli
# mgua@tomware.it
# mar 2022
#
# - Place this hostedit.ps1 file in 
#   c:\windows\system32\drivers\etc
#
# - configure it accordingly to your names 
#   editing $wsl_name and $names variables
#
# - execute it when needed from a powershell admin prompt
#
# ------------
# you can send commands to your wsl using the name of the wsl
# as an executable, or just use "wsl" 
# c:\kali.exe -c "ip address list | grep eth0 | grep inet"
# c:\kali.exe -c "ip address list | grep 'scope global eth0'"
# c:\wsl ip a l eth0
#
# here is how we get the current ip address
# wsl -d "kali-linux" hostname -I
#
#
# the following netsh commands can be used to bind 
# specified tcp ports on the localhost
#
# so that you can reach them on 127.0.0.1
#netsh interface portproxy add v4tov4 listenport=22 connectport=22 connectaddress=$wsl_ip
#netsh interface portproxy add v4tov4 listenport=80 connectport=80 connectaddress=$wsl_ip
#netsh interface portproxy add v4tov4 listenport=443 connectport=443 connectaddress=$wsl_ip
#
#
##################

$HostsFile = 'C:\Windows\System32\drivers\etc\hosts'
$NewHostsFile = 'C:\Windows\System32\drivers\etc\newhosts'
$CommandsChainFile = 'C:\Windows\System32\drivers\etc\cmdchain.txt'

# check your wsl name with wsl --list
#$wsl_name = 'Ubuntu-20.04'
$wsl_name = 'kali-linux'
# write here the aliases you would like to add to the hosts file


#$names = @("kswin", "kslinux.tomware.it", "kslinux", "lix", "ksl", "klx", "g2g_ks.4ru.it")
$names = @("wsl", "kali", "mykali", "kalihost", "mgkali", "mgk", "acme01.com", "acme02.com")


# here we get the ip of the wsl system
$wsl_ips = (wsl -d $wsl_name hostname -I).trim().split()
# it can be that there are more than one ip address
# PS C:\WINDOWS\system32> (wsl -d Ubuntu-20.04 hostname -I).trim()
# 172.30.4.131 172.26.160.1
# in this case i get the second one, being the first the ip of the host (windows) machine
# if i get back a list, i choose the second element
if ($wsl_ips.Count -gt 1) {
	write-host Detected multiple IP addresses: $wsl_ips
	# im getting the last ip of the list
	$wsl_ip = $wsl_ips[-1]
} else {
	write-host Detected single IP address: $wsl_ips
	$wsl_ip = $wsl_ips
}
write-host Selected ip: $wsl_ip
#echo wsl_ip: $wsl_ip


if (-not(Test-Path -Path $HostsFile -PathType Leaf)) {
	Write-Host "FATAL: file $HostsFile not found."
	Exit 222
}

if (Test-Path -Path $NewHostsFile -PathType Leaf) {
	Write-Host "FATAL: $NewHostsFile already exist. Please delete."
	Exit 223
}

# create I/O streams
$stream_reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $HostsFile
$stream_writer = New-Object -TypeName System.IO.StreamWriter -ArgumentList $NewHostsFile

while (($line =$stream_reader.ReadLine()) -ne $null){
	# bypass any line containing wsl hostnames and copy the rest
	$found = $FALSE
	foreach ($name in $names) {
		# check if $name appears with a space in front of it
		# using case insensitive match
        if ($line -match "\W" + $name) {
			$found = $TRUE
		}
	}
	if (-not $found) {
		$stream_writer.WriteLine($line)					
		}
}

# then we add the required lines to hosts file, with the current ip
foreach ($name in $names) {
	$stream_writer.WriteLine($wsl_ip + " " + $name)			
}

$stream_writer.close()
$stream_reader.close()

# take a backup copy of current hosts file
$dateFormat = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
$HostsFileBak = $HostsFile + '_' + $dateFormat  + '.backup'
Remove-Item -path $HostsFileBak >$null 2>&1
Move-Item -path $HostsFile -Destination $HostsFileBak

# move the newhost file overwriting the old one
Move-Item -path $NewHostsFile -Destination $HostsFile

# report actions just on screen
Write-Host "Hosts file [$HostsFile] updated with:"
foreach ($name in $names) {
	Write-Host "  $wsl_ip $name"			
}



# now if we find a command chain file we launch those commands on the wsl
# $CommandsChainFile = 'C:\Windows\System32\drivers\etc\cmdchain.txt'

if (Test-Path -Path $CommandsChainFile -PathType Leaf) {
	Write-Host "sending commands from $CommandsChainFile to $wsl_name"
	$cmd_stream_reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $CommandsChainFile
	while (($line = $cmd_stream_reader.ReadLine()) -ne $null){
		# send commands to wsl host, skipping comments lines starting with #
	        if (-not($line -match '\s*#')) {
			Write-Host "  sending command: $line"			
			$output = & wsl -d $wsl_name $line
			Write-Host $output
		}
	}
	$cmd_stream_reader.close()
	Read-Host -Prompt "Press any key to complete"
}


Exit 0



 
