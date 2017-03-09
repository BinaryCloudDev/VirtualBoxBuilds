# VirtualBox Builds

### Background
I got tired of Packer builds failing randomly for unexplained reasons, and wanted more control and explicit understanding over an automated build process.

### Bibliography
This project borrows heavily from MWRock's work with Packer Template (https://github.com/mwrock/packer-templates).

This project also uses things a number of things:
* BFI (Build Floppy Image): http://www.softpedia.com/get/System/Boot-Manager-Disk/BFI.shtml
* Petri IT's Test-PSRemoting function: https://www.petri.com/test-network-connectivity-powershell-test-connection-cmdlet (modified to add the port parameter)
