

Function Invoke-WindowsApi( 
    [string] $dllName,  
    [Type] $returnType,  
    [string] $methodName, 
    [Type[]] $parameterTypes, 
    [Object[]] $parameters 
    )
{
  ## Begin to build the dynamic assembly 
  $domain = [AppDomain]::CurrentDomain 
  $name = New-Object Reflection.AssemblyName 'PInvokeAssembly' 
  $assembly = $domain.DefineDynamicAssembly($name, 'Run') 
  $module = $assembly.DefineDynamicModule('PInvokeModule') 
  $type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit") 

  $inputParameters = @() 

  for($counter = 1
 $counter -le $parameterTypes.Length
 $counter++) 
  { 
     $inputParameters += $parameters[$counter - 1] 
  } 

  $method = $type.DefineMethod($methodName, 'Public,HideBySig,Static,PinvokeImpl',$returnType, $parameterTypes) 

  ## Apply the P/Invoke constructor 
  $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string]) 
  $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName 
  $method.SetCustomAttribute($attr) 

  ## Create the temporary type, and invoke the method. 
  $realType = $type.CreateType() 

  $ret = $realType.InvokeMember($methodName, 'Public,Static,InvokeMethod', $null, $null, $inputParameters) 

  return $ret
}

Function Set-PrivateProfileString( 
    $file, 
    $category, 
    $key, 
    $value) 
{
  ## Prepare the parameter types and parameter values for the Invoke-WindowsApi script 
  $parameterTypes = [string], [string], [string], [string] 
  $parameters = [string] $category, [string] $key, [string] $value, [string] $file 

  ## Invoke the API 
  [void] (Invoke-WindowsApi "kernel32.dll" ([UInt32]) "WritePrivateProfileString" $parameterTypes $parameters)
}

####Install RRAS role####

Import-Module ServerManager

Install-WindowsFeature RemoteAccess -IncludeManagementTools

Add-WindowsFeature -name Routing -IncludeManagementTools

####!!! NOTE: A reboot of the machine might be required here after which the script can be executed again.#####

# Install S2S VPN
Import-Module RemoteAccess
if ((Get-RemoteAccess).VpnS2SStatus -ne "Installed")
{
  Install-RemoteAccess -VpnType VpnS2S
}

# Add and configure S2S VPN interface
Add-VpnS2SInterface -Protocol IKEv2 -AuthenticationMethod PSKOnly -NumberOfTries 3 -ResponderAuthenticationMethod PSKOnly -Name "104.41.128.221"  -Destination "104.41.128.221" -IPv4Subnet @("10.0.0.0/28:100") -SharedSecret abc123

Set-VpnServerIPsecConfiguration -EncryptionType MaximumEncryption
# default value for Windows 2012 is 100MB, which is way too small. Increase it to 32GB.
Set-VpnServerIPsecConfiguration -SADataSizeForRenegotiationKilobytes 33553408

New-ItemProperty -Path HKLM:\System\CurrentControlSet\Services\RemoteAccess\Parameters\IKEV2 -Name SkipConfigPayload -PropertyType DWord -Value 1

# Set S2S VPN connection to be persistent by editing the router.pbk file (required admin priveleges)
Set-PrivateProfileString $env:windir\System32\ras\router.pbk "104.41.128.221" "IdleDisconnectSeconds" "0"
Set-PrivateProfileString $env:windir\System32\ras\router.pbk "104.41.128.221" "RedialOnLinkFailure" "1"


# Dial-in to Azure gateway
Connect-VpnS2SInterface -Name "104.41.128.221" 
