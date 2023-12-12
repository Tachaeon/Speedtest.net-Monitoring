#Logging
Start-Transcript -Path "$env:TEMP\BWM.log" -Append

#Time in Seconds to rescan IP address
$ConnectedTime = 1800
$DisconnectedTime = 300

#Upload and download thresholds
$MinDownload = 150
$MinUpload = 50

#Settings for Email
$Password = ConvertTo-SecureString '' -AsPlainText -Force
$SMTPServer = ""
$Port = "587"
$From = ""
$To = ""

###################
#End User Settings#
###################

#Download File
$ProgressPreference = 'SilentlyContinue'
$SpeedTestInstaller = "SpeedTest.zip"
$WebClient = New-Object System.Net.WebClient 
$URL = 'https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip'
$ZipFile = "$env:TEMP\$SpeedTestInstaller" 
$ExeFile = "$env:TEMP\speedtest.exe"

#Download if doesn't exist
if (!(Get-Item $ExeFile -ErrorAction SilentlyContinue)) {
    $WebClient.DownloadFile($URL, $ZipFile)
    Expand-Archive -Path $ZipFile -DestinationPath $env:TEMP -ErrorAction SilentlyContinue
}

#Connected
function Connected {
    While ($true) { 
        $Speedtest = & $ExeFile --format=json --accept-license --accept-gdpr
        $Speedtest | Out-File "$env:TEMP\Last.txt" -Force
        $Speedtest = $Speedtest | ConvertFrom-Json
        [PSCustomObject]$SpeedObject = @{
            DownloadSpeed = [math]::Round($Speedtest.download.bandwidth / 1000000 * 8, 2)
            UploadSpeed   = [math]::Round($Speedtest.upload.bandwidth / 1000000 * 8, 2)
            PacketLoss    = [math]::Round($Speedtest.packetLoss)
            ISP           = $Speedtest.isp
            ExternalIP    = $Speedtest.interface.externalIp
            InternalIP    = $Speedtest.interface.internalIp
            UsedServer    = $Speedtest.server.host
            URL           = $Speedtest.result.url
            Jitter        = [math]::Round($Speedtest.ping.jitter)
            Latency       = [math]::Round($Speedtest.ping.latency)
        }
        If ($Downloadspeed -gt $MinDownload -or $Uploadspeed -gt $MinUpload) {
            Clear-Host
            $Date = Get-Date
            Write-Host 'Log File Location'`n'-----------------'`n"$env:TEMP\BWM.log"
            $SpeedObject
            Write-Host ''
            Write-Host 'Last Run'`n'--------'
            $Date.DateTime
            Start-Sleep $ConnectedTime
        }
        elseif ($Downloadspeed -lt $MinDownload -or $Uploadspeed -lt $MinUpload) {
            Send-MailMessage @mailParams -Subject "Speed Test is Bad!"
            Disconnected
        }   
    }
}

#If Disconnected
function Disconnected {
    While ($true) {
        $Speedtest = & $ExeFile --format=json --accept-license --accept-gdpr
        $Speedtest | Out-File "$env:TEMP\Last.txt" -Force
        $Speedtest = $Speedtest | ConvertFrom-Json
        [PSCustomObject]$SpeedObject = @{
            DownloadSpeed = [math]::Round($Speedtest.download.bandwidth / 1000000 * 8, 2)
            UploadSpeed   = [math]::Round($Speedtest.upload.bandwidth / 1000000 * 8, 2)
            PacketLoss    = [math]::Round($Speedtest.packetLoss)
            ISP           = $Speedtest.isp
            ExternalIP    = $Speedtest.interface.externalIp
            InternalIP    = $Speedtest.interface.internalIp
            UsedServer    = $Speedtest.server.host
            URL           = $Speedtest.result.url
            Jitter        = [math]::Round($Speedtest.ping.jitter)
            Latency       = [math]::Round($Speedtest.ping.latency)
        }
        If ($Downloadspeed -lt $MinDownload -or $Uploadspeed -lt $MinUpload) {
            Clear-Host
            $Date = Get-Date
            Write-Host 'Log File Location'`n'-----------------'`n"$env:TEMP\BWM.log"
            $SpeedObject
            Write-Host ''
            Write-Host 'Last Run'`n'--------'
            $Date.DateTime
            Start-Sleep $DisconnectedTime
        }
        elseif ($Downloadspeed -gt $MinDownload -or $Uploadspeed -gt $MinUpload) {
            Send-MailMessage @mailParams -Subject "Speed Test is Good!"
            Connected
        }
    }
}

#Initial Test
$Speedtest = & $ExeFile --format=json --accept-license --accept-gdpr
$Speedtest | Out-File "$env:TEMP\Last.txt" -Force
$Speedtest = $Speedtest | ConvertFrom-Json
 
[PSCustomObject]$SpeedObject = @{
    DownloadSpeed = [math]::Round($Speedtest.download.bandwidth / 1000000 * 8, 2)
    UploadSpeed   = [math]::Round($Speedtest.upload.bandwidth / 1000000 * 8, 2)
    PacketLoss    = [math]::Round($Speedtest.packetLoss)
    ISP           = $Speedtest.isp
    ExternalIP    = $Speedtest.interface.externalIp
    InternalIP    = $Speedtest.interface.internalIp
    UsedServer    = $Speedtest.server.host
    URL           = $Speedtest.result.url
    Jitter        = [math]::Round($Speedtest.ping.jitter)
    Latency       = [math]::Round($Speedtest.ping.latency)
}

#Variables for Email
$Credential = New-Object System.Management.Automation.PSCredential ('operations@brightway.email', $password)
$Downloadspeed = $SpeedObject.DownloadSpeed
$Uploadspeed = $SpeedObject.UploadSpeed
$PacketLoss = $SpeedObject.PacketLoss
$ISP = $SpeedObject.isp
$ExternalIP = $SpeedObject.ExternalIP
$InternalIP = $SpeedObject.InternalIP
$UsedServer = $SpeedObject.UsedServer
$URL = $SpeedObject.URL
$Jitter = $SpeedObject.Jitter
$Latency = $SpeedObject.Latency

#HTML Template
$EmailBody = @"
<table border="0" cellpadding="1" cellspacing="1" style="height:257px; width:1198px">
<tbody>
<tr>
    <td style="width:308px"><img alt="this slowpoke moves" src="https://i.gifer.com/X0XF.gif" style="float:left; height:149px; width:266px" /></td>
    <td rowspan="1" style="width:876px"><u><strong><span style="font-size:small"><span style="font-size:11pt">Internet Speed Test:</span></span></strong></u><br />
    <span style="font-size:small"><span style="font-size:11pt">Download Speed - <span style="color:#3498db">$Downloadspeed</span></span></span><br />
    Upload Speed - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$Uploadspeed</span></span></span><br />
    Packetloss - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$PacketLoss</span></span></span><br />
    ISP - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$ISP</span></span></span><br />
    External IP - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$ExternalIP</span></span></span><br />
    Internal IP - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$InternalIP</span></span></span><br />
    Used Server - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$UsedServer</span></span></span><br />
    URL - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$URL</span></span></span><br />
    Jitter - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$Jitter</span></span></span><br />
    Latency - <span style="font-size:small"><span style="font-size:11pt"><span style="color:#3498db">$Latency</span></span></span></td>
</tr>
</tbody>
</table>
"@

# Define the Send-MailMessage parameters
$mailParams = @{
    SmtpServer                 = $SMTPServer
    Port                       = $Port
    UseSSL                     = $true
    BodyAsHtml                 = $true
    Credential                 = $Credential
    From                       = $From
    To                         = $To
    Body                       = $EmailBody
    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
}

if ($Downloadspeed -gt $MinDownload -or $Uploadspeed -gt $MinUpload) {
    Send-MailMessage @mailParams -Subject "Speed Test is Good!"
    Connected
} 
elseif ($Downloadspeed -lt $MinDownload -or $Uploadspeed -lt $MinUpload) {
    Send-MailMessage @mailParams -Subject "Speed Test is Bad!"
    Disconnected
}