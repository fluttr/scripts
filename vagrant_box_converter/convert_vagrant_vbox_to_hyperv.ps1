#Requires -Version 3
<#
.Synopsis
    Converts Vagrant .box file from VirtualBox provider to Hyperv provider
    Experimental, use at your own risk.
    
    Script uses technique described by Matt Wrock: 
    http://www.hurryupandwait.io/blog/creating-a-hyper-v-vagrant-box-from-a-virtualbox-vmdk-or-vdi-image

    Script requires VBoxManage.exe and 7zip archiver. 
    If VirtualBox is not installed in standard path, specify path to VBoxManage.exe with $VBoxManagePath
    If 7z.exe cannot be found in PATH specify it with $7zPath    
#>

param(
  [parameter(Mandatory = $true)][string]$InputBoxPath,
  [parameter(Mandatory = $true)][string]$OutputBoxPath,
  [string]$7zPath,
  [string]$VBoxManagePath = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe',
  [string]$TmpDir = "$PSScriptRoot\tmp",
  [switch]$ConvertImageToVhdx,         # TODO? Now converting only to .vhd
  [ValidateSet(1,2)][int]$VmGeneration # TODO. Now creating box only for gen. 1
)

if(-not "$7zPath"){
    if(-not ($7zPath = $(Get-Command '7z'))){
        throw "7z.exe is not found nor specified."
    }
}
if(-not $(Test-Path "$VBoxManagePath")){
    if(-not ($VBoxManagePath = $(Get-Command 'VBoxManage'))){
        throw "VBoxManage.exe is not found nor specified."
    }
}
Set-Variable VMTemplateXmlPath -Option ReadOnly -Value "$PSScriptRoot\_hyperv_vm_template.xml"
if(-not $(Test-Path "$VMTemplateXmlPath")){
    throw "Hyper-V vm template is not found at expected path '$VMTemplateXmlPath'"
}
if(-not $("$OutputBoxPath".Split('.')[-1] -eq 'box')){
    $OutputBoxPath += '.box'
}
if($(test-path "$TmpDir")){
    rm -Recurse -Force "$TmpDir"
}
$vmConfigDir = "$TmpDir\Virtual Machines"
$vmImageDir = "$TmpDir\Virtual Hard Disks"
mkdir "$vmConfigDir","$vmImageDir"



# Extracting Vagrant box which is gzipped tar
. "$7zPath" x -o"$TmpDir" "$InputBoxPath"                                                                  
$tar = gci "$TmpDir\*" -File
. "$7zPath" x -o"$TmpDir" "$tar"                                                                                                 
rm -Force $tar

pushd "$TmpDir"

# Skip converting for .vhd disk images
if($vhdImages = (gci -File -Path "$TmpDir\*.vhd")){
    foreach($vhd in $vhdImages){
        mv "$vhd" "$vmImageDir"
    }
}

# Searching for images to convert
$supportedFormats = 'vmdk','vdi'
$driveImages = @()
foreach($driveFormat in $supportedFormats){
    $driveImages += gci -Path "*.$driveFormat"
}
if($driveImages.Length -gt 1){
    Write-Warning "Box contains more than one drive image which is not supported yet."
    Write-Warning "Only first image will be added to new box."
    Write-Output "Drive images: "
    $driveImages
}

# Converting images to Hyper-V format
if($image = $driveImages[0]){
    $newImage = "$vmImageDir\$($image.BaseName).vhd"
    . $VBoxManagePath clonemedium --format vhd "$image" "$newImage"
    if($(Get-Command Optimize-VHD -ErrorAction SilentlyContinue)){
        # Reduce image size if possible
        $isProcessElevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
        if($isProcessElevated){
            Optimize-VHD -Mode Full "$newImage"
        } else {
            "Can't to optimize drive image because script running without elevated priveleges."
        }
    }
    rm -Force $image
}

# Making sure that at least one .vhd image exists
$driveImages = gci -Path "$vmImageDir\*.vhd" -File
if(-not $driveImages){
    throw "Box does not contain drive image or conversion to .vhd gone wrong."
}

# TODO: import settings from .ovf to template through intermediate [xml]
# see https://github.com/hashicorp/vagrant/blob/master/plugins/providers/hyperv/scripts/import_vm_xml.ps1

# Populating template for hyper-v box
[xml]$vmConfig = Get-Content $VMTemplateXmlPath
$node = $vmConfig.SelectSingleNode("//type[.='VHD']")
$node.ParentNode.pathname.'#text' = "$($driveImages[0].Name)"
$vmConfig.Save("$vmConfigDir\vm.xml")
    
# Creating metadata.json
@{"provider" = "hyperv"} | ConvertTo-Json | Set-Content "$TmpDir\metadata.json"

# OVF file is not used by Hyper-V so we removing it
$ovfFile = gci -Path "$TmpDir\*.ovf"
if($ovfFile){
    rm -Force "$ovfFile"
}

popd

# Compressing contents into new box
. $7zPath a -ttar "${OutputBoxPath}.tar" "$TmpDir\*"
. $7zPath a -tgzip "${OutputBoxPath}" "${OutputBoxPath}.tar"

# Cleanup
rm -Force -Recurse "$TmpDir"
rm -Force "${OutputBoxPath}.tar"

Write-Host -ForegroundColor Green "Box '$InputBoxPath' converted to '$OutputBoxPath'"
echo "You can (try to) add it with following commands:`n"
echo "vagrant box add box_name file:///L:/path/to/$(split-path -leaf $OutputBoxPath)"
echo "vagrant init box_name"
echo "vagrant up --provider hyperv"

