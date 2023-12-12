# Speedtest.net-Monitoring
Bandwidth monitoring script that checks a upload and download of "X" every number of seconds.

## Settings
##### Time in Seconds to rescan IP address.
- $ConnectedTime = 1800
- $DisconnectedTime = 300

##### Upload and download thresholds.
- $MinDownload = 150
- $MinUpload = 50

##### Settings for Email.
- $Password = ConvertTo-SecureString '**Your Password Here**' -AsPlainText -Force
- $SMTPServer = "your.smtpserver.com"
- $Port = "587"
- $From = "bob@bob.com"
- $To = "bobjr@bob.com"

## How to use
- If the bandwidth is **_above_** the $MinDownload and $MinUpload then it will retest every $ConnectedTime and send an email. (30 Min)
- If the bandwidth is **_below_** the $MinDownload and $MinUpload then it will retest every $DisconnectedTime and send an email. (5 Min)
