function Invoke-SNMPget ([string]$sIP, $sOIDs, [string]$Community = "public", [int]$UDPport = 161, [int]$TimeOut=3000) {
    # $OIDs can be a single OID string, or an array of OID strings
    # $TimeOut is in msec, 0 or -1 for infinite
 
    # Create OID variable list
    #$vList = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable                        # PowerShell v1 and v2
     $vList = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'                          # PowerShell v3
    foreach ($sOID in $sOIDs) {
        $oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($sOID)
        $vList.Add($oid)
    }
 
    # Create endpoint for SNMP server
    $ip = [System.Net.IPAddress]::Parse($sIP)
    $svr = New-Object System.Net.IpEndPoint ($ip, 161)
 
    # Use SNMP v2
    $ver = [Lextm.SharpSnmpLib.VersionCode]::V2
 
    # Perform SNMP Get
    try {
        $msg = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get($ver, $svr, $Community, $vList, $TimeOut)
    } catch {
        Write-Host "SNMP Get error: $_"
        Return $null
    }
 
    $res = @()
    foreach ($var in $msg) {
        $line = "" | Select OID, Data
        $line.OID = $var.Id.ToString()
        $line.Data = $var.Data.ToString()
        $res += $line
    }
 
    $res
}

function Invoke-SnmpWalk ([string]$sIP, $sOIDstart, [string]$Community = "public", [int]$UDPport = 161, [int]$TimeOut=3000) {
    # $sOIDstart
    # $TimeOut is in msec, 0 or -1 for infinite
 
    # Create OID object
    $oid = New-Object Lextm.SharpSnmpLib.ObjectIdentifier ($sOIDstart)
 
    # Create list for results
    #$results = New-GenericObject System.Collections.Generic.List Lextm.SharpSnmpLib.Variable                       # PowerShell v1 and v2
     $results = New-Object 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'                         # PowerShell v3
 
    # Create endpoint for SNMP server
    $ip = [System.Net.IPAddress]::Parse($sIP)
    $svr = New-Object System.Net.IpEndPoint ($ip, 161)
 
    # Use SNMP v2 and walk mode WithinSubTree (as opposed to Default)
    $ver = [Lextm.SharpSnmpLib.VersionCode]::V2
    $walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree
 
    # Perform SNMP Get
    try {
        [Lextm.SharpSnmpLib.Messaging.Messenger]::Walk($ver, $svr, $Community, $oid, $results, $TimeOut, $walkMode)
    } catch {
        Write-Host "SNMP Walk error: $_"
        Return $null
    }
 
    $res = @()
    foreach ($var in $results) {
        $line = "" | Select OID, Data
        $line.OID = $var.Id.ToString()
        $line.Data = $var.Data.ToString()
        $res += $line
    }
 
    $res
}
#############################
#My Code
#############################
#Invoke-SnmpGet "192.168.38.11" "1.3.6.1.2.1.17.7.1.2.2"
#Invoke-SnmpWalk "192.168.38.11" ".1.3.6.1.2.1.17.7.1.4.3.1.1"
#Invoke-SnmpWalk "192.168.38.11" ".1.3.6.1.2.1.17.4.3.1"	#default vlan

function findonswitch ([string]$ip) {
$oid=".1.3.6.1.2.1.17.7.1.2.2.1.2."
$mas = Invoke-SnmpWalk $ip ".1.3.6.1.2.1.17.7.1.2" #vlans
$i=0
$vlan=@()
$mac=@()
$port=@()
foreach ($pt in $mas)
{
		if ($pt.OID -like "*$oid*")
		{
			$pt.OID = $pt.OID.remove(0,28)
			$vlan += $pt.OID.Substring(0, $pt.OID.IndexOf("."))
			$temp = $pt.OID.Substring($pt.OID.IndexOf(".") + 1, $pt.OID.Length - $pt.OID.IndexOf(".")-1)
			###перевод из Dec в Hex
			$mas=$temp.split(".")
			$nmac=@()
			foreach ($sdec in $mas)
			{
				$dec = [int]$sdec
				$nmac += '{0:X2}' -f $dec
			}
			$str=$nmac -join "-"
			###
			$mac += $str
			$port += $pt.Data
		}
		
}
$return= @{}
$return.vlan=$vlan
$return.mac=$mac
$return.port=$port
return $return
}

###############################################################################
$rootIP = "192.168.38.21"
$sport = ("1", "2", "5", "12", "13", "14", "43", "44", "65", "66", "74", "107")
$swDB = ("192.168.38.42", "192.168.38.44", "192.168.38.61", "192.168.38.52", "192.168.38.51", "192.168.38.12", "192.168.38.33", "192.168.38.32", "192.168.38.41", "192.168.38.43", "192.168.38.11", "192.168.38.34")

function findinarr ($array, $value) {
    for ($i=0; $i -lt $array.count;$i++) { 
        if($array[$i] -eq $value){$i}
    }
}

#$dataRoot = Import-CSV -path $path$rootDB | Select-Object MAC, Port
$res=findonswitch $rootIP
$dataMACRoot = $res.mac
$dataPortRoot = $res.port
$dataVlanRoot = $res.vlan
$mac = Read-Host "Enter MAC"
if ($mac.indexof(":") -ne 0)
{
	$mac=$mac.replace(":", "-")
}
$i=0
$flag=0
foreach ($S in $dataMACRoot)
{	
	if ($mac -eq $s)
	{
		$portRoot = $dataPortRoot[$i]
		$vlanRoot = $dataVlanRoot[$i]
		Write-Host $mac on $portRoot 'in vlan' $vlanRoot on RootSwitch	
		if ($flag -eq 0)
		{
			$portRoot1 = $dataPortRoot[$i]
		}
		$flag++
	}
	$i++
}

$A = findinarr $sport $portRoot1

$res=findonswitch $swDB[$A]
$dataMAC = $res.mac
$dataPort = $res.port
$dataVlan = $res.vlan
$i=0
foreach ($S in $dataMAC)
{
	if ($mac -eq $s)
	{
		$port = $dataPort[$i]
		$vlan = $dataVlan[$i]
		Write-Host $mac on $port 'in vlan' $vlan on 'switch' $swDB[$A]
	}
	$i++
}

