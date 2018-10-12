#Parameters for the template, what user name, size, OS etc.

#Refer https://github.com/PowerShell/PowerShell/issues/2736 - without this function the converted JSON is having spaces all over the places, which New-AzureRmResourceGroupDeployment can handle but its not pretty/hard to read.
function Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json) {
  $indent = 0;
  ($json -Split '\n' |
    % {
      if ($_ -match '[\}\]]') {
        # This line contains  ] or }, decrement the indentation level
        $indent--
      }
      $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
      if ($_ -match '[\{\[]') {
        # This line contains [ or {, increment the indentation level
        $indent++
      }
      $line
  }) -Join "`n"
}
#Parameters Template - based on this a template will be created for deployment dynamically -Parameters4Deployment.json
$ParmatersMasterPath = "C:\Temp\I9\ParametersMasterv15.0.json"
#Template for the VM 
$TemplateMasterPath = "C:\Temp\I9\TemplateMasterv15.0.json" 
#Input fields
$parametersCSV = IMport-csv "C:\Temp\I9\ServerParameters.csv"
#Set storage context
#Get-AzureRmStorageAccount -ResourceGroupName i9vms | where {$_.storageaccountName -like "sa*"} |set-AzureRmcurrentStorageAccount
#$KeyvaultID=(Get-AzureRmKeyVault -ResourceGroup TRGVMsRG | Select ResourceID).ResourceID
#Variables
$virtualMachineName=@();$i=0;$vmImageType=@();$osPublisher=@();$osOffer=@();$osSKU=@();$osType=@();$virtualMachineSize=@() #VM resource
$P7Pair=@();$IM94FDiskSourceArr=@();#Future for I9 project.
$PrivateIP=@();$publicIpAddressName=@();$PublicIPRequired=@();$subnetName=@();$virtualNetworkName=@();$networkSecurityGroupName=@(); #NIC resource
$FDiskAccountType=@();$FDiskCreateOption=@();$FDiskSize=@();$isIM94Machine=@(); #Fdisk resource
$GDiskAccountType=@();$GDiskCreateOption=@();$GDiskSize=@(); #GDiskresource
$networkSecurityGroupName=@();$ResourceGroupName=@()     


#$DiagActinfo= Get-AzureRmStorageAccount -ResourceGroupName i9vms | where {$_.storageaccountName -like "vmsdiag*"}|Select ID,StorageAccountName
#$diagstorageaccountname=$DiagActinfo.StorageAccountName
#$diagstorageaccountID=$DiagActinfo.ID

#set-AzureRmcurrentStorageAccount -ResourceGroupName trgvmsrg -StorageAccountName $StorageAccountName
$CustomImagescontainerName ="customimages"
$CustomScriptsContainerName = "customscripts"

Foreach($row in $parametersCSV)
{
$serverParam = (Get-Content $ParmatersMasterPath) -join "`n" | ConvertFrom-Json
#We are building an army of arrays that will fed into a single file parameters4deployment based on the csv file.
#Parameters like VMnames will need to be captured as array.
#$ResourceGroupName = $row.ResourceGroupName
$virtualMachineName+=$row.virtualMachineName
$virtualMachineSize+=$row.virtualMachineSize
$virtualNetworkName+=$row.virtualNetworkName
$vmImageType+=$row.vmimagetype
$osPublisher+=$row.osPublisher
$osOffer+=$row.osOffer
$osSKU+=$row.osSKU
$osType+=$row.osType
$subnetName+=$row.subnetName

$P7Pair+=$row.P7Pair
$PublicIPRequired+=$row.PublicIPRequired
$PrivateIP+=$row.PrivateIP
$isIM94Machine+=$row.isIM94Machine
$FDiskAccountType+=$row.FDiskAccountType
$FDiskSize+=$row.FDiskSize
$FDiskCreateOption+=$row.FDiskCreateOption

#$GDiskSize+=$row.GDiskSize
#$GDiskCreateOption+=$row.GDiskCreateOption
#$GDiskAccountType+=$row.GDiskAccountType
$networkSecurityGroupName+=$row.networkSecurityGroupName
[string]$IM4FdiskSource=""
$IM4FdiskSource= $row.P7Pair+"-FDisk"
$IM94FDiskSourceArr+=$IM4FdiskSource

}

$serverParam.parameters.virtualMachineName.value=$virtualMachineName
$serverParam.parameters.virtualMachineSize.value=$virtualMachineSize
$serverParam.parameters.virtualNetworkName.value=$virtualNetworkName
$serverParam.parameters.vmimagetype.value=$vmimagetype

$serverParam.parameters.osPublisher.value=$osPublisher
$serverParam.parameters.osOffer.value=$osOffer
$serverParam.parameters.osSKU.value=$osSKU
$serverParam.parameters.osType.value=$osType
$serverParam.parameters.subnetName.value=$subnetName

$serverParam.parameters.P7Pair.value=$P7Pair
$serverParam.parameters.PublicIPRequired.value=$PublicIPRequired
$serverParam.parameters.PrivateIP.value=$PrivateIP
$serverParam.parameters.isIM94Machine.value=$isIM94Machine

$serverParam.parameters.FDiskAccountType.value=$FDiskAccountType
$serverParam.parameters.FDiskSize.value=$FDiskSize
$serverParam.parameters.FDiskCreateOption.value=$FDiskCreateOption

#$serverParam.parameters.GDiskSize.value=$GDiskSize
#$serverParam.parameters.GDiskCreateOption.value=$GDiskCreateOption
#$serverParam.parameters.GDiskAccountType.value=$GDiskAccountType
$serverParam.parameters.networkSecurityGroupName.value=$networkSecurityGroupName
######################

#Dynamic parameter template for deployment - uses ParametersMaster.json for reference.
[string]$Parameters4DeploymentPath="C:\Temp\I9\Parameters4Deployment.json"
$serverParam | ConvertTo-Json -depth 100 | Format-Json | Set-Content $Parameters4DeploymentPath
#https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-multiple 
#Refer above article to understand the variables section and /virtualmachine resource section.
#Resource can be called as copyindex() but properties needs to be referred like copyindex(array,startingvalue)

New-AzureRmResourceGroupDeployment -Name "Webserver1deployment1" -ResourceGroupName "I9VMS" -TemplateParameterFile "$Parameters4DeploymentPath" -TemplateFile "$TemplateMasterPath"