$az_sub = 'ff2c4422-50d1-48c6-bccf-0f4aa7e4963d'
$resource_gp = "Camilyo_rp"
$resource_lc = 'East US'
$storageType = 'Standard_B1s'
$TotalVmNumber = 4



#USER INPUT
$VMname = Read-Host  -Prompt 'Please enter your VM prefix : '
[int]$VmCount =  Read-Host -Prompt 'Please enter the number of VMs wanted: '

##Set SUB
Set-AzContext -Subscription $az_sub
New-AzResourceGroup -Name $resource_gp -Location $resource_lc

Write-Host "number of vm is  '$VmCount ' and prefix is '$VMname' "

##check lf if number proivided is bigger then allowed

if($VmCount -le $TotalVmNumber){
    try{
        $cred = Get-Credential
    }
    catch{ 
        $_| Out-File C:\error-camilyo.txt -Append
        break
    }

        if ($VmCount %2 -eq 0) {
            Write-Host "Creatin VMS"
            $jobs = 1..$VmCount | ForEach-Object -Parallel {
                $newVmname = $VMname + '-' + $_   
                $vmParams = @{
                    ResourceGroupName = $resource_gp
                    Name = $VMname-$_  
                    Location = $resource_lc
                    VirtualNetworkName = $VMname +"Vnet"
                    SubnetName = $VMname +"sub"
                    PublicIpAddressName = $VMname +'-'+ $_ +'-pip'
                    Credential = $cred
                    OpenPorts = 3389
                    AsJob = $true
                }
                New-AzVM @vmParams
            } -ThrottleLimit 5 
            Wait-Job $jobs | Out-Null
            
            
            Get-AzResource -ResourceGroupName $resource_gp -Name $newVmname.Tags
            $jobs = for ($i=1;($i -le $VmCount); $i++) {
                $newVmname = $VMname + '-' + $_
                if($i %2 -eq 0){
                    "$ServiceName"
                    $tags = @{"Status"="Shutdown"} | Get-AzResource -ResourceGroupName $resource_gp -ResourceType Microsoft.Compute/virtualMachines -Name $newVmname | Set-AzResource -Tag $tags -Force -AsJob  
                }
                "$VmCount running in even"
                      
            }
            Wait-Job $jobs | Out-Null
           
        }
        else{
            for ($i=1;($i -le $VmCount); $i++) {
                        New-AzVM  -ResourceGroupName $resource_gp -Name $newVmname -Location $resource_lc -VirtualNetworkName $vnetName -SubnetName $subNetName -PublicIpAddressName $publicIpaddr -OpenPorts  $oPorts
                        $dataDiskName  = $newVmname + '_datadisk'
                        $diskConfig = New-AzDiskConfig -SkuName $storageType -Location $resource_lc -CreateOption Empty -DiskSizeGB 10
                        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $resource_gp
                    
                         Add-AzVMDataDisk -VM $newVmname -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
                        "$newVmname"
                        "$VmCount is odd"
                        Write-Progress -Activity "Update Progress" -Status "$Vmcount% Complete:" -PercentComplete $Vmcount;
        
                    }
            }
            Wait-Job $jobs | Out-Null
    }
    
    else{
        "$VmCount is bigger then 4 - run again"
    }
