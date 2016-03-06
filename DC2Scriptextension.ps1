
$ErrorActionPreference = "Continue"

#Set all DNS addresses needed.
write-verbose -Verbose "Set all DNS addresses needed."
$local = "127.0.0.1"
$DC = "10.0.1.4"


route add 172.20.2.0 mask 255.255.255.0 10.0.0.5

#Combine addresses
write-verbose -Verbose "Combining DNS addresses."
$dns = "$DC", "$local"

#Set network adapter ranges
write-verbose -Verbose "Setting network adapter ranges."

#Get Network adapters
write-Verbose -Verbose "Now checking available network adapters."
$Net = Get-NetAdapter | select ifIndex | ft -a | Out-File -FilePath C:/Netadapter.txt
$Net =  "C:/Netadapter.txt"

#Setting ranges to work with
$Ranges = (Get-Content $Net) -creplace "ifIndex", "" -creplace "-", "" | foreach {$_.Trim()} | Where { $_ } | Sort #| out-file C:/Netadapter.txt

#Execute DNS change
write-Warning -Verbose "Now executing DNS change to all available network adapters."
foreach ($range in $ranges)    {
Set-DnsClientServerAddress -InterfaceIndex $range -ServerAddresses ($DNS)
}

New-Item C:\log\newlog.txt -ItemType file -Force

route add 10.0.1.0 mask 255.255.255.240 10.0.0.5

# Add Second DC

        Install-WindowsFeature AD-Domain-Services
        $password = ConvertTo-SecureString -AsPlainText -String "Ironman1979" -Force
        Import-Module ADDSDeployment
        $DatabasePath = "C:\Windows\NTDS"
        $LogPath = "C:\Windows\NTDS"
        $SysvolPath = "C:\Windows\SYSVOL"
        If (Get-Disk | Where-Object {($_.BusType -eq "SCSI") -or ($_.BusType -eq "SAS")}) {
            $DatabasePath = (Get-Partition -DiskNumber (Get-Disk | Where-Object {($_.BusType -eq "SCSI") -or ($_.BusType -eq "SAS")} | Sort-Object Number)[0].Number).DriveLetter + ":\Windows\NTDS"
            $LogPath = (Get-Partition -DiskNumber (Get-Disk | Where-Object {($_.BusType -eq "SCSI") -or ($_.BusType -eq "SAS")} | Sort-Object Number)[0].Number).DriveLetter + ":\Windows\NTDS"
            $SysvolPath = (Get-Partition -DiskNumber (Get-Disk | Where-Object {($_.BusType -eq "SCSI") -or ($_.BusType -eq "SAS")} | Sort-Object Number)[0].Number).DriveLetter + ":\Windows\SYSVOL"
            If ((Get-Disk | Where-Object {($_.BusType -eq "SCSI") -or (.BusType -eq "SAS")}).Count -gt 1) {
                $LogPath = (Get-Partition -DiskNumber (Get-Disk | Where-Object {($_.BusType -eq "SCSI") -or ($_.BusType -eq "SAS")} | Sort-Object Number)[1].Number).DriveLetter + ":\Windows\NTDS"
            }
        }
        Install-ADDSDomainController -DomainName "coretek.com" -InstallDns:$true -SafeModeAdministratorPassword  -CreateDnsDelegation:$false -DatabasePath $DatabasePath -LogPath $LogPath -SysvolPath $SysvolPath -NoRebootOnCompletion:$false -Force:$true
 

