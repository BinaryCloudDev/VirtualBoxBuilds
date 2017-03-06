$vm = "Server2012R2"

VBoxManage createvm --name $vm --ostype WindowsNT_64 --register

#create a hard drive, 20GB, dynamic allocation
VBoxManage createhd --filename $vm --size 20480 --format VDI

#add a sata controller with the dynamic disk
VBoxManage storagectl $vm --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $vm --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$($vm).vdi"

#add an ide controller with dvd drive and install iso
VBoxManage storagectl $vm --name "IDE Controller" --add ide
VBoxManage storageattach $vm --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium ./9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO

#this sucks. gotta find a slicker way to build this image
Remove-Item ./floppy.img -ErrorAction SilentlyContinue
bfi -f=.\floppy.img .\floppy

vboxmanage storagectl $vm --name "Floppy" --add floppy
vboxmanage storageattach $vm --storagectl "Floppy" --port 0 --device 0 --type fdd --medium .\floppy.img

#set some settings
VBoxManage modifyvm $vm --ioapic on
VBoxManage modifyvm $vm --boot1 dvd --boot2 disk
VBoxManage modifyvm $vm --memory 2048 --vram 48 --cpus 2 --natpf1 "guest_winrm,tcp,127.0.0.1,55985,,5985"

#start the vm
vboxmanage startvm $vm