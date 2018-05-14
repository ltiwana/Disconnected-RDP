################ DISCRIPTION ##########################
# Purpose of this script is to find out disconnected sessions for usernames listed in $UserNames array
# Important: Make sure to update $rootFolder path
# $username variable stores username to scan. You can also feed these from a text file
# $Errorfile is a file location to collect server that do not respond to query user command
# $DownServer is a file location to collect server that do not respond to ping request

$UserNames = "user1", "user2","user3"

$rootfolder = "D:\SessionLogs\" # make sure to change this path

$ErrorFile = "$rootfolder\ServerWithError.txt"
$DownServer = "$rootfolder\ServerDown.txt"



Write-Host "`n`nLooking for disconnected RDP session on all AD servers...`n"

# This is to measure current windows size to show * for better display
$LineSize = $null
$LineSize = (get-host).ui.rawui.windowsize.width
if ($LineSize -eq $null -or !$LineSize) {$LineSize = "80"}

# Import the Active Directory module for the Get-ADComputer CmdLet
Import-Module ActiveDirectory

# Get today's date for the report
$today = Get-Date

# Query Active Directory for enabled windows servers computer accounts
$Servers = Get-ADComputer -Filter {(OperatingSystem -like "*windows*server*") -and (Enabled -eq "True")} | Sort Name

# Initializing variables
$SessionList = $NULL
$queryResults = $NULL
$SError = $null
$SDown = $null
$z = 0
$count = $Servers.count

# Start looping through each server
ForEach ($Server in $Servers) {

        # variables for displaying progress
        $z = $z + 1
        $Percent = [math]::Round($($($z/$count*100)))

        $ServerName = $Server.Name

        Write-Progress -Activity "Processing Server: $z out of $count servers." -Status " Current Progress: $Percent`%     ||     Current Server: $ServerName" -PercentComplete ($z/$Servers.count*100)

        # check if server is online
        if (Test-Connection $Server.Name -Count 1 -Quiet) {
            Write-Host "`n`n$ServerName is online!" -BackgroundColor Green -ForegroundColor Black

            Write-Host ("`nQuerying Server: `"$ServerName`" for all disconnected sessions..") -BackgroundColor Gray -ForegroundColor Black

            # Store any disconnected RDP session in this variable
            [array]$queryResults += (

                # query the server for RDP sessions
                query user /server:$ServerName 2>&1 | foreach {

                    # check if RDP session is disconnected. We do not want to pick active session
                    # However, You can remove this to pick all RDP sessions
                    if ($_ -match "Disc") {

                        # replace the tabbed spaces with comma and add servername in front of it
                        write-output ("`n$ServerName," + (($_.trim() -replace ' {2,}', ',')))
                    }

                    # if unable to run query user command throw the server in Error variable
                    if ($_ -match "The RPC server is unavailable") {[array]$SError += ($ServerName)}
                }

            )
        }
        else {

            # if the server does not respond ping then add it to down server variable
            [array]$SDown += ($ServerName)
            Write-Host "`nError: Unable to connect to $ServerName!" -BackgroundColor red -ForegroundColor white
            Write-Host "Either the $ServerName is down or check for firewall settings on server $ServerName!" -BackgroundColor Yellow -ForegroundColor black
        }
    }

# You can convert the below if statements to functions
# if statement is used to find servers with query user command error
if ($SError -ne $null -and $SError) {

    # display any servers with query user command errors
    Write-Host "`nScript was unable to query following servers, probably due to firewall:" -ForegroundColor White -BackgroundColor Red
    $SError
    Write-Host "`n`n"

    # start looping the servers with errors
    # This piece is just for visual
    foreach ($ServerError in $SError){

        # check if error file exists already
        if (test-path $ErrorFile) {

            $serrortest = $false

            # go through the server in the files and compare them with servers in $SError variable
            Get-Content $ErrorFile | foreach {
                if  ($_ -eq $ServerError) {

                    $serrortest = $true
                }
            }

            # Any server that are not in $SError mark them as newly found server display on screen
            if (!$serrortest) {
                Write-Host "Found a new server with error: $ServerError"

            }
        }

    }

    # export all errored out server to error file
    $SError | Out-File $ErrorFile
}

# if statement is similar to above but it creates file for offline servers
if ($SDown -ne $null -and $SDown) {
    Write-Host "`nScript was unable to connect to the following server:" -ForegroundColor White -BackgroundColor Red
    $SDown
    Write-Host "`n`n"
    foreach ($ServerDown in $SDown) {
        if (test-path $DownServer) {
            $sdowntest = $false
            Get-Content $DownServer | foreach {
                if  ($_ -eq $ServerDown) {

                    $sdowntest = $true
                }
            }
            if (!$sdowntest) {
                Write-Host "Found a new down server: $ServerDown"
            }
        }

    }
    $SDown | Out-File $DownServer
}


Write-Host ("`n`n`n`n" + "*" * $LineSize)

# This is where script finds if there a some disconnected RDP sessions for admin usernames
if ($queryResults -ne $null -and $queryResults) {
    Write-Host "`n`nFound some ghost RDP sessions`n" -ForegroundColor White -BackgroundColor Red

    # take out any empty lines
    $queryResults = $QueryResults.split("`n") -match '\S'
    foreach ($username in $UserNames) {
        $userfound = $false

        # initiate a temporary file
        Out-File -OutVariable $null -FilePath $rootfolder\temp.file -Force -Confirm:$false
        Write-Host "`nLooking for $username's ghost sessions..." -BackgroundColor Yellow -ForegroundColor black

        # go through query user results one by one
        $queryResults | foreach {

            # find a match for username
            if ($_ -match $username) {

                Write-Host "Found session for $username" -ForegroundColor White -BackgroundColor Red
                $_

                # store the output in temp file
                # I had to store it in a temp file, for some reason storing it in a variable wasn't working properly
                $_ | Out-File -FilePath $rootfolder\temp.file -Append
                #[array]$userfound =+ $string
                #[array]$NewErrorFile =+ $ServerError
                $userfound = $true
            }
        }

        # based on userfound value append the output to .csv file
        if (!$userfound) {

            Write-Host "** You are all good! No ghost sessions found! **" -BackgroundColor Green -ForegroundColor Black
            Write-Output "You are all good! No ghost sessions found!" | Out-File $rootfolder\$username.csv -Force

        }
        else {
           Get-Content "$rootfolder\temp.file" |  Out-File -FilePath "$rootfolder\$username.csv" -Force -Confirm:$false
        }

    }

}
Write-Host ("`n" + "*" * $LineSize)

sleep 10

#remove the temp file
Remove-Item "$rootfolder\temp.file" -Force -Confirm:$false
