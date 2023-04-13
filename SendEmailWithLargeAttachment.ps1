##Auth Variables
$clientSecret = '' | ConvertTo-SecureString -AsPlainText -Force
$clientId = ''
$tenantId = ''


#Email Addresses
$fromUPN = ""
$toUPN = ""


#File info
$file = "" ##Full file path including extension Ex. C:\folder\file.zip
$fileName = [System.IO.Path]::GetFileName($file)


##Byte the file
$fileBytes = [System.IO.File]::ReadAllBytes($file)
$fileLength = $fileBytes.Length


##Get Token
$token = Get-MsalToken -ClientId $clientId -ClientSecret $clientSecret -TenantId $tenantId -ForceRefresh


##Create Email Draft
$params = @{
    Subject      = "Please Find Attached File: $fileName"
    Importance   = "Low"
    Body         = @{
        ContentType = "HTML"
        Content     = "Please find $fileName attached to this email. Thank you."
    }
    ToRecipients = @(
        @{
            EmailAddress = @{
                Address = $toUPN
            }
        }
    )
}
$emailDraft = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/beta/users/$fromUPN/messages/" -Headers @{Authorization = "Bearer $($Token.AccessToken)" } -Body ($params | ConvertTo-Json -Depth 99) -ContentType 'application/json'


##Create Attachment Session
$params = @{
    AttachmentItem = @{
        AttachmentType = "file"
        Name           = $fileName
        Size           = $fileLength
    }
}
$createAttachmentSession = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/beta/users/$fromUPN/messages/$($emailDraft.Id)/attachments/createUploadSession" -Headers @{Authorization = "Bearer $($Token.AccessToken)" } -Body ($params | ConvertTo-Json -Depth 99) -ContentType 'application/json'


##Chunk the file
$PartSizeBytes = 320 * 1024 # 327680
$index = 0
$start = 0
$end = 0
while ($fileLength -gt ($end + 1)) {
    $start = $index * $PartSizeBytes
    if (($start + $PartSizeBytes - 1) -lt $fileLength) {
        $end = ($start + $PartSizeBytes - 1)
    }
    else {
        $end = ($start + ($fileLength - ($index * $PartSizeBytes)) - 1)
    }  
      
    [byte[]]$body = $fileBytes[$start..$end]
    write-host $body.Length.ToString()
    $headers = @{
        'Content-Length' = $body.Length.ToString()
        'Content-Range'  = "bytes $start-$end/$fileLength"
    }  
    write-Host "bytes $start-$end/$fileLength | Index: $index and ChunkSize: $PartSizeBytes"
    $response = Invoke-WebRequest -Method Put -Uri $createAttachmentSession.uploadUrl -Body $body -Headers $headers
    
    $index++
}


##Send the email
$sendEmail = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/beta/users/$fromUPN/messages/$($emailDraft.Id)/send" -Headers @{Authorization = "Bearer $($Token.AccessToken)" }