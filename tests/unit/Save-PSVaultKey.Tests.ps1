﻿$script:ModuleName = 'PSVault'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase = Split-Path -Parent $MyInvocation.MyCommand.Path
# For tests in .\Tests subdirectory
while ((Split-Path $ModuleBase -Leaf) -ne $ModuleName) {
  $ModuleBase = Split-Path $ModuleBase -Parent
}

#Variables
$SecureString       = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
$Credential1            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential3            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null


Describe "Function" -Tags Build , Unit{
#remove artifacts from previous runs
  Get-ChildItem $env:LOCALAPPDATA\PSVault -filter pester* -Recurse|Remove-Item
  Get-ChildItem $env:LOCALAPPDATA\psvault -Recurse -Include * -Exclude Keys -Directory|Remove-Item -force -Recurse
  
  $TemporaryFolder = New-Item "$env:LOCALAPPDATA\PSVault\Test_$(Get-date -Format yyyyMMddHHmm)\Pester" -ItemType Directory
  
  $aftereachContext =  {
    if (-not [String]::IsNullOrEmpty($KeyLocation)) {
      remove-item $KeyLocation -Force -ErrorAction SilentlyContinue
      remove-variable -Name SavedKeyLocation -ErrorAction SilentlyContinue
    } 
    if (-not [String]::IsNullOrEmpty($location)) {
      remove-item $location -Force -ErrorAction SilentlyContinue
      Remove-Variable -Name Location -ErrorAction SilentlyContinue
    }
  }
  
    
  context 'Save-PSVaultKey -Vault (New-PSVault -Name Test -VaultPassword $SecureString)' {
    it 'creates a vault with the name "Test" and saves the key.' {
      $vault = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
      $script:location = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Save-PSVaultKey -Vault $vault
      } | should not throw
    }
    it ('It will be saved in {0}.' -f $KeyLocation) {
      Test-Path $location|should be true
    }
  }
  & $aftereachContext

  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}
