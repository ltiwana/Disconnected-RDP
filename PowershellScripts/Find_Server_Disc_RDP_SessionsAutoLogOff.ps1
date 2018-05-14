################ DISCRIPTION ##########################
# purpose of this script is to check admin account lock out status
# Important: Make sure to update $rootFolder path
# and to check if user wants to log out of their sessions
# username.logoff file is create by vb.net program when user click on Forcelogoff
# username.logoff indicates to script that user want to logout all off their sessions


$error.Clear()
$ErrorActionPreference = "Stop"


try {
    Import-Module "ActiveDirectory"
    [int]$num = "1"
    do {

        # I am counting the number of time the script runs, just for visual affects
        # I am running the script few times
        Write-Host "Number of script run: $num"

        # $username variable stores username to scan. You can also feed these from a text file
        $UserNames = "user1", "user2","user3"

        $rootfolder = "D:\SessionLogs\" # make sure to change this path

        # go through each user one by one
        foreach ($UserName in $UserNames) {

            # check if the admin account is locked out
            # if it is locked then create username.locked file else remove it
            # username.locked file is used in vb.net to show lockout status
            if ((Get-ADUser $UserName -Properties lockedout).lockedout -eq $true) {
                New-Item -ItemType file $rootfolder\$username.locked -Force
            }
            else {
                if (Test-Path $rootfolder\$username.locked) {
                    Remove-Item -Path "$rootfolder\$username.locked" -Force -Confirm:$false
                }
            }

            # check if the username specific logoff file is found
            If (Test-Path $rootfolder\$UserName.logoff) {

                # instead of querying all user sessions again, I rely on .csv file
                if (Test-Path $rootfolder\$username.csv) {

                    # if the file contains no ghost session found text then no need to go through logoff
                    if (!(Get-Content $rootfolder\$username.csv | Select-String "No ghost sessions found") ) {

                        # import all session from csv file to start logoff process
                        import-csv $rootfolder\$username.csv -Header  servername,username, sessionid, currentdate, idealtime,logontime| foreach {

                            # I save id and servername in new variable or else the command line has issues with $_
                            $id = $_.sessionid
                            $srvname = $_.servername
                            Write-Host "Checking $username session on $srvname..."

                            # i am putting a double check here. Maybe the user logged back into the server
                            # since the RDP session capturing is happening ever five minutes the csv file could be stale
                            # this makes sure that captured session in csv file is disconnected before logging it off
                            if (qwinsta /server:$srvname | Select-String "$username" | Select-String "disc") {
                                logoff $id /server:$srvname /v

                                # if no error in logging off then update the file with your sessions are cleared
                                # I know if 1 out of 10 session get cleared below if statement will be executed
                                # but it will be captured by the query user session script again
                                # you can actually take this further by just taking out the relative line out of csv file
                                if (!$?) {
                                    Remove-Item -Path "$rootfolder\$username.logoff" -Force -Confirm:$false
                                    #Remove-Item -Path "$rootfolder\$username.csv" -Force -Confirm:$false
                                    Write-Output "You are all good! No ghost sessions found!" | Out-File "$rootfolder\$username.csv" -Force -Confirm:$false
                                }

                            }
                            else {
                                Write-Output "You are all good! No ghost sessions found!" | Out-File "$rootfolder\$username.csv" -Force -Confirm:$false
                                Remove-Item -Path "$rootfolder\$username.logoff" -Force -Confirm:$false
                                Write-Host "No session found for user $username on server $srvname!"
                            }
                        }
                    }
                    else {
                        Write-Output "You are all good! No ghost sessions found!" | Out-File "$rootfolder\$username.csv" -Force -Confirm:$false
                        Remove-Item -Path "$rootfolder\$username.logoff" -Force -Confirm:$false
                        Write-Host "No session found for user $username on server $srvname!"
                    }
                }
            }
        }

        # There is reason for putting a 25 second wait time and looping through 9 times.
        # You will need to run this script as a scheduled task and scheduled task only allows a task to run every 5 minutes
        # If the admin user click on Force logoff they will have to wait for 5 minutes before their sessions get logged out
        # by looping 9 times and with 25 seconds wait, gives me a total of 4 minutes 15 seconds
        # Script will be run by scheduled task after 45 seconds
        # this reduces the vb.net or front-end update time and admin will get a status update with in 30 seconds window
        Write-Host "Waiting for 25 seconds.."
        $num++
        sleep 25
    } while ($num -le "9")
}
catch {
    Write-host "Error: "$error
    # you can have the script send an email to you with error message
    # send-mailmessage -to youremail
}