
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
        Install-ADDSDomainController -DomainName "new.com" -InstallDns:$true -SafeModeAdministratorPassword  -CreateDnsDelegation:$false -DatabasePath $DatabasePath -LogPath $LogPath -SysvolPath $SysvolPath -NoRebootOnCompletion:$false -Force:$true
 

