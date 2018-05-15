# Disconnected-RDP
### Find Disconnected/Orphaned Remote Desktop Sessions App

How I created a small App that helped our admins to stay on top of their disconnected and orphaned Remote Desktop Connections (RDP). 

**Reason for developing it:**
1. The primary goal: We automate our password changes so if the AD account password is changed while there is still an RDP connection left behind that is using the old password, the AD account would lock out.
2. Users have more control and visibility over their RDP connections.
3. Some RDP connections were left open willingly to run jobs or processes, so I didn't want to force a logoff policy.

![alt text](/Images/Main.png)

**Development:**

Front-end is developed in vb.net and backend is developed in PowerShell.



**Back-end process (PowerShell):**
1. Powershell script that runs every 5 minutes and queries all enabled (only) AD servers (computer accounts). Command used: Query User /Server:ServerName
2. Saves all sessions into a variable
3. Formatting and sorting:
   * Format sessions in CSV format
   * Filter and select only disconnected sessions
   * Filter further and select only admin account sessions
4. Save all disconnected sessions info for each user in a separate CSV file (file/peruser.)



**Front-end process (vb.net):**
1. Auto refresh every 10 seconds
2. Get currently logged in username to look up the relevant CSV file
3. Generate a .net grid view from the CSV file
4. Force logoff button which creates a "UserName.Logoff" file, letting the second PowerShell script know that user wants to log off all their disconnected sessions.


**Back-end script 2:**
1. Check for any "Username.Logoff" files
2. If a logoff file is found then import disconnected RDP sessions from the CSV files (relevant to username) and start logging off the disconnected RDP sessions.
3. Update the CSV file with success message.

Start here: https://github.com/ltiwana/Disconnected-RDP/wiki
