"Automated QC program.  Window will close automatically when finshed"
"For details contact: Christopher Hall, ch15@sanger.ac.uk"

& "C:\Users\Operator\Documents\R\R-3.6.0\bin\Rscript.exe" "D:\BDQC\QCscript v6.R"

$username = ""
$password = ""
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

[array]$toattach = Get-ChildItem "D:\BDQC\Images" *.png

$From = ""
$To = ""
$Attachment = $toattach.fullname
$Subject = "FT1 sample quality report: 10% threshold"
$Body = Get-Content -Path D:\BDQC\Summaries\tosend.txt -Raw
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
if($Attachment) {            
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $cred -Attachments $Attachment -DeliveryNotificationOption OnSuccess
} else {            
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $cred -DeliveryNotificationOption OnSuccess
}
New-Item -ItemType Directory -Path "D:\BDQC\Archive\$((Get-Date).ToString('yyyy-MM-dd'))"
Move-Item -Path D:\BDQC\Images\*.png -Destination D:\BDQC\Archive\$((Get-Date).ToString('yyyy-MM-dd'))
