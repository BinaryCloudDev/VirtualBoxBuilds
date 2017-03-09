. "libraries\New-IsoFile.ps1"
. "libraries\Test-PSRemoting.ps1"

#VARIABLES
$vm = "Server2012R2"
$vmLocation = "$($home)\VirtualBox VMs\$($vm)"
$iso = "./9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO"
$guestAdditionsISO = "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"
$Timeout = 600
$CheckEvery = 10
$username = "vagrant"
$password = "vagrant"

#delete and recreate the output directory
Remove-Item ./output -Recurse -Force -ErrorAction SilentlyContinue
mkdir ./output

#nuke the vm if it exists
#should probably try to catch this error and do something slick or check to see if the vm exists before deleting
$null = VBoxManage unregistervm $vm --delete 2>&1
Remove-Item $vmLocation -ErrorAction SilentlyContinue -Recurse -Confirm:$false -Force

VBoxManage createvm --name $vm --ostype WindowsNT_64 --register

#create a hard drive, 20GB, dynamic allocation
$disk = VBoxManage createhd --filename "$($vmLocation)\$vm" --size 20480 --format VMDK
$uuid = $disk -replace "Medium created. UUID: ", ""

#add a sata controller with the dynamic disk
VBoxManage storagectl $vm --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $vm --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$($vmLocation)\$($vm).vmdk"

#add an ide controller with dvd drive and install iso
VBoxManage storagectl $vm --name "IDE Controller" --add ide
VBoxManage storageattach $vm --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $iso

#this sucks. gotta find a slicker way to build this image
Remove-Item ./floppy.img -ErrorAction SilentlyContinue
./bfi -f=c:\wip\vbox\floppy.img .\floppy

vboxmanage storagectl $vm --name "Floppy" --add floppy
vboxmanage storageattach $vm --storagectl "Floppy" --port 0 --device 0 --type fdd --medium .\floppy.img

#set some settings
VBoxManage modifyvm $vm --ioapic on
VBoxManage modifyvm $vm --boot1 dvd --boot2 disk
VBoxManage modifyvm $vm --memory 2048 --vram 48 --cpus 2 --natpf1 "guest_winrm,tcp,127.0.0.1,55985,,5985"

#start the vm
vboxmanage startvm $vm

#Start the timer
$timer = [Diagnostics.Stopwatch]::StartNew()

$password = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object -Typename System.Management.Automation.PSCredential -argumentlist $username, $password

#Wait until WinRM is available
Write-Host "Waiting until WinRM is available..."
while (-not (Test-PSRemoting -ComputerName localhost -Port 55985 -Credential $cred))
{
    Write-Verbose -Message "Waiting for [$($ComputerName)] to become pingable..."
    ## If the timer has waited greater than or equal to the timeout, throw an exception exiting the loop
    if ($timer.Elapsed.TotalSeconds -ge $Timeout)
    {
       throw "Timeout exceeded. Giving up machine being ready."
    }
    ## Stop the loop every $CheckEvery seconds
    Start-Sleep -Seconds $CheckEvery
}
Write-Host "WinRM is available. Continuing..."

Write-Host "Mounting and Installing VirtulBox Guest Additions..."
#unmount iso (windows dvd)
VBoxManage storageattach $vm --storagectl "IDE Controller" --port 0 --device 0 --medium emptydrive

#mount guest additions
VBoxManage storageattach $vm --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $guestAdditionsISO

#do a bunch of other stuff
Write-Host "Provisioning a bunch of stuff..."
Invoke-Command -ComputerName Localhost -Port 55985 -Credential $cred -ScriptBlock { A:\provision.ps1 }

#unmount iso vbox guest additions and floppy
VBoxManage storageattach $vm --storagectl "IDE Controller" --port 0 --device 0 --medium emptydrive

#sysprep VM
Write-Host "Sysprepping the vm..."
Invoke-Command -ComputerName Localhost -Port 55985 -Credential $cred -ScriptBlock { A:\PackerShutdown.bat } -ErrorAction SilentlyContinue

Write-Host "Ejecting the floppy drive..."
VBoxManage storageattach $vm --storagectl "Floppy" --port 0 --device 0 --type fdd --medium emptydrive

Write-Host "Exporting the VM to the output directory..."
vboxmanage export Server2012R2 --output output/box.ovf --ovf20
