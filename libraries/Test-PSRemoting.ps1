#taken from https://www.petri.com/test-network-connectivity-powershell-test-connection-cmdlet and modified to add port parameter
 
Function Test-PSRemoting {
[cmdletbinding()]
 
Param(
[Parameter(Position=0,Mandatory,HelpMessage = "Enter a computername",ValueFromPipeline)][ValidateNotNullorEmpty()][string]$Computername,
[string]$Port = 5985,
[System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
)
 
Begin {
    Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
} #begin
 
Process {
  Write-Verbose -Message "Testing $computername"
  Try {
    $r = Test-WSMan -ComputerName $Computername -Port $Port -Credential $Credential -Authentication Default -ErrorAction Stop
    $True 
  }
  Catch {
    Write-Verbose $_.Exception.Message
    $False
 
  }
 
} #Process
 
End {
    Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
} #end
 
} #close function