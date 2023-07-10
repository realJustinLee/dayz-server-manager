<# 
.SYNOPSIS 
	Script for download and management of DayZ server and mods.
	
.DESCRIPTION 
	This script can be used for download of SteamCMD, DayZ server data and DayZ server mod data.
	It can also run DayZ server with specified user configuration (launch parameters, server configuration file).
	
.NOTES 
	File Name  : Server_manager.ps1 
	Author : Bohemia Interactive a.s. - https://feedback.bistudio.com/project/view/2/
	Requires  : PowerShell V4
	Supported OS  : Windows 10, Windows Server 2012 R2 or newer
	
.LINK 
	https://community.bistudio.com/wiki/...

.EXAMPLE 
	Open Main menu:
	 C:\foo> .\Server_manager.ps1
 
.EXAMPLE 
	Update server:
	 C:\foo> .\Server_manager.ps1 -update server
	 
.EXAMPLE 
	Update both server and mods and start server with user config:
	 C:\foo> .\Server_manager.ps1 -u all -s start -lp user
	 
.EXAMPLE 
	Stop running servers:
	 C:\foo> .\Server_manager.ps1 -s stop
	 
.PARAMETER update 
   Update server and/or mods to latest version. Can be substituted by -u
   
   Use values:
   server - updates DayZ server data
   mod - updates selected mod data
   all - updates both DayZ server and mod data
   
.PARAMETER u
   Update server and/or mods to latest version. Can be substituted by -update
   
   Use values:
   server - updates DayZ server data
   mod - updates selected mod data
   all - updates both DayZ server and mod data
   
.PARAMETER server 
   Start or stop DayZ server. Can be substituted by -s
   Can be combined with -launchParam or -lp parameters.
   
   Use values:
   start - start DayZ server
   stop - stop running DayZ servers
   
.PARAMETER s
   Start or stop DayZ server. Can be substituted by -server
   Can be combined with -launchParam or -lp parameters.
   
   Use values:
   start - start DayZ server
   stop - stop running DayZ servers
   
.PARAMETER launchParam
   Choose if Dayz server should start with default or user launch parameters. Can be substituted by -lp
   Must be used in combination with -server or -s parameters.
   Default value is used if not specified otherwise.
   
   Use values:
   default - start DayZ server with default launch parameters
   user - start DayZ server with user launch parameters
   
.PARAMETER lp
   Choose if Dayz server should start with default or user launch parameters. Can be substituted by -launchParam
   Must be used in combination with -server or -s parameters.
   Default value is used if not specified otherwise.
   
   Use values:
   default - start DayZ server with default launch parameters
   user - start DayZ server with user launch parameters

.PARAMETER app 
   Select which Steam server application you want to use.
   Can be combined with all other parameters.
   Default value "stable" is used if not specified.
   
   Use values:
   stable - Stable Steam server app
   exp - Experimental Steam server app
  
#> 

#Comand line parameters
param
(
	[string] $u = $null,
	[string] $update = $null,
	[string] $s = $null,
	[string] $server = $null,
	[string] $lp = $null,
	[string] $launchParam = $null,
	[string] $app = $null
)

#Prepare variable for selection in menus
$select = $null

#Prepare variables related to user Documents folder
$userName = $env:USERNAME
$docFolder = $PWD.ToString() + '\ServerManagerDoc'
$steamDoc = $docFolder + '\SteamCmdPath.txt'
$modListPath = $docFolder + '\modListPath.txt'
$serverModListPath = $docFolder + '\serverModListPath.txt'
$modServerPar = $docFolder + '\modServerPar.txt'
$serverModServerPar = $docFolder + '\serverModServerPar.txt'
$userServerParPath = $docFolder + '\userServerParPath.txt'
$pidServer = $docFolder + '\pidServer.txt'
$tempModList = $docFolder + '\tempModList.txt'
$tempModListServer = $docFolder + '\tempModListServer.txt'

#Prepare variables related to SteamCMD folder
$steamApp = $null
$appFolder = $null
$folder = $null
$loadMods = $null


#Main menu
function Menu {

	Write-Output "`n"
	Write-Output "Menu:"
	Write-Output "1) Server update"
	Write-Output "2) Mod update"
	Write-Output "3) Start server"
	Write-Output "4) Stop running server"
	Write-Output "5) Uninstall/Remove saved"
	Write-Output "6) Exit"
	Write-Output "`n"

	$select = Read-Host -Prompt 'Please select desired action from menu above'
	
	switch ($select) {
		#Call server update and related functions
		1 {
			Write-Output "`n"
			Write-Output "Server update selected"
			Write-Output "`n"
			
			SteamCMDFolder
			SteamCMDExe
			SteamLogin
			
			Menu

			Break
		} 

		#Call mods update and related functions
		2 {
			Write-Output "`n"
			Write-Output "Mod update selected"
			Write-Output "`n"
						
			SteamCMDFolder
			SteamCMDExe
			SteamLogin
						
			Menu

			Break
		}

		#Start DayZ server
		3 {
			Write-Output "`n"
			Write-Output "Start server selected"
			Write-Output "`n"
								
			SteamCMDFolder
								
			$select = $null
								
			Server_menu
								
			Menu

			Break
		}

		#Stop running server
		4 {
			Write-Output "`n"
			Write-Output "Stop running server selected"
			Write-Output "`n"
										
			ServerStop
										
			Menu

			Break
		}

		#Purge saved login/path info
		5 {
			Write-Output "`n"
			Write-Output "Uninstall/Remove saved selected"
			Write-Output "`n"
												
			Remove_menu
                
			Break
		}

		#Close script
		6 {
			Write-Output "`n"
			Write-Output "Exit selected"
			Write-Output "`n"
														
			exit 0

			Break
		}

		#Force user to select one of provided options
		Default {
                
			Write-Output "`n"
			Write-Output "Select number from provided list (1-6)"
			Write-Output "`n"
																
			Menu
		}
	}
}


#SteamCMD folder
function SteamCMDFolder {
	#Check for file with path to SteamCMD folder
	if (!(Test-Path "$steamDoc")) {
		#Prompt user to insert path to SteamCMD folder
		$script:folder = Read-Host -Prompt 'Insert path where is or where will be created SteamCMD folder (without quotation marks)'

		#Check if path was really inserted
		if ($folder -eq "") {
			Write-Output "`n"
			Write-Output "No folder path inserted! Returning to Main menu..."
			Write-Output "`n"
					
			Menu
		}
			
		Write-Output "`n"
		Write-Output "Selected SteamCMD folder is $folder"
		Write-Output "`n"
			
		#Create SteamCMD folder if it doesn't exist
		if (!(Test-Path "$folder")) {
			Write-Output "Selected SteamCMD folder created"
			Write-Output "`n"
					
			mkdir "$folder" >$null
		}

		#Prompt user to save path to SteamCMD folder for future use
		$saveFolder = Read-Host -Prompt 'Do you want to save path for future use? (yes/no)'

		if ( ($saveFolder -eq "yes") -or ($saveFolder -eq "y")) { 	
			#Create DayZ_Server folder if it doesn't exist
			if (!(Test-Path "$docFolder")) {
				mkdir "$docFolder" >$null
			}
					
			#Save path to SteamCMD folder
			$folder | Set-Content "$steamDoc"
					
			Write-Output "`n"
			Write-Output "Path saved to $steamDoc"
			Write-Output "`n"
		}
	}
	else {
		#Use saved path to SteamCMD folder
		$script:folder = Get-Content "$steamDoc"
					
		Write-Output "Selected SteamCMD folder is $folder"
		Write-Output "`n"
					
		#Create SteamCMD folder if it doesn't exist
		if (!(Test-Path "$folder")) {
			Write-Output "Selected SteamCMD folder created"
			Write-Output "`n"
							
			mkdir "$folder" >$null
		}
	}
}


#SteamCMD exe
function SteamCMDExe {
	#Check if SteamCMD.exe exist
	if (!(Test-Path "$folder\steamcmd.exe")) {
		Write-Output "`n"
		#Prompt user to download and install SteamCMD
		$steamInst = Read-Host -Prompt "'$folder\steamcmd.exe' not found! Do you want to download and install it to previously chosen folder? (yes/no)"
		Write-Output "`n"
			
		if ( ($steamInst -eq "yes") -or ($steamInst -eq "y")) { 
			Write-Output "Downloading and installing SteamCMD..."
			Write-Output "`n"

			#Get Powershell version for compatibility check
			$psVer = $PSVersionTable.PSVersion.Major

			if ($psVer -gt 3) { 

				Write-Output "Using Powershell version $psVer"
				Write-Output "`n"

				#Download SteamCMD
				$downloadURL = "http://media.steampowered.com/installer/steamcmd.zip"
				$destPath = "$folder\steamcmd.zip"

                            (New-Object System.Net.WebClient).DownloadFile($downloadURL, $destPath)

				#Unzip SteamCMD
				$shell = New-Object -ComObject Shell.Application
				$zipFile = $shell.NameSpace($destPath)
				$unzipPath = $shell.NameSpace("$folder")

				$copyFlags = 0x00
				$copyFlags += 0x04 # Hide progress dialogs
				$copyFlags += 0x10 # Overwrite existing files

				$unzipPath.CopyHere($zipFile.Items(), $copyFlags)
						
				#If Powershell version is under 4
			}
			else { 
				Write-Output "`n"
				Write-Output "Wrong Powershell version $psVer !"
				Write-Output "`n"
			}
					
			#Update SteamCMD to latest version
			Start-Process -FilePath "$folder\steamcmd.exe" -ArgumentList ('+quit') -Wait -NoNewWindow
					
			Start-Sleep -Seconds 1 
					
			if (Test-Path "$folder\steamcmd.exe") {
				#Remove SteamCMD zip file after successful installation
				Remove-Item -Path "$folder\steamcmd.zip" -Force
							
				Write-Output "`n"
				Write-Output "SteamCMD was successfully installed."
				Write-Output "`n"
							
			}
			else {
				#Throw error if SteamCMD doesn't exist after installation
				Write-Output "$folder\steamcmd.exe not found!"
				Write-Output "`n"
									
				pause
									
				Menu
			}
		}
		else {
			#Throw error if SteamCMD doesn't exist and user chose not to install
			Write-Output "$folder\steamcmd.exe not found!"
			Write-Output "`n"
							
			pause
							
			Menu
		}			
	}
}

#Steam login
function SteamLogin {
	#Path to encrypted Steam login files
	$steamLog1 = $docFolder + '\SteamLog1.txt'
	$steamLog2 = $docFolder + '\SteamLog2.txt'

	#If one or both files don't exist
	if (!(Test-Path "$steamLog1") -or !(Test-Path "$steamLog2")) {
		Write-Output "`n"
		#Prompt user to save Steam login to encrypted file for future use
		$slogin = Read-Host -Prompt 'Do you want to save Steam login for future use? (yes/no)'
		Write-Output "`n"

		if ( ($slogin -eq "yes") -or ($slogin -eq "y")) { 	
			#Create DayZ_Server folder if it doesn't exist
			if (!(Test-Path "$docFolder")) {
				mkdir "$docFolder" >$null
			}
					
			#Save Steam login details to encrypted files
			#Steam username
			$steamUs = Read-Host -Prompt 'Insert Steam username'
			Write-Output "`n"
					
			$secureSteamUs = ConvertTo-SecureString -String $steamUs -AsPlainText -Force
			$secureSteamUs | ConvertFrom-SecureString | Set-Content "$steamLog1"
					
			#Steam password
			$secureSteamPw = Read-Host -Prompt 'Insert Steam password' -AsSecureString
					
			$secureSteamPw | ConvertFrom-SecureString | Set-Content "$steamLog2"
			$steamPw = (New-Object PSCredential $userName, $secureSteamPw).GetNetworkCredential().Password
					
			Write-Output "`n"
			Write-Output "Steam login saved to encrypted file"
			Write-Output "`n"

		}
		else {
			#Log in Steam without save of credentials
			$steamUs = Read-Host -Prompt 'Insert Steam username'
			Write-Output "`n"

			$securePw = Read-Host -Prompt 'Insert Steam password' -AsSecureString
			Write-Output "`n"
							
			$steamPw = (New-Object PSCredential $userName, $securePw).GetNetworkCredential().Password

		}
	}
	else {
		#Use stored Steam login credentials
		$secureUser = Get-Content "$steamLog1" | ConvertTo-SecureString
		$steamUs = (New-Object PSCredential $userName, $secureUser).GetNetworkCredential().Password
					
		$securePw = Get-Content "$steamLog2" | ConvertTo-SecureString
		$steamPw = (New-Object PSCredential $userName, $securePw).GetNetworkCredential().Password
					
		Write-Output "Using stored Steam login credentials"
		Write-Output "`n"
						
	}
		
	#Server update selected
	if ($select -eq '1') { 
		ServerUpdate
	}
		
	#Mods update selected
	if ($select -eq '2') { 
		ModsUpdate
	}
		
}
				
#Update DayZ server data
function ServerUpdate {
	
	Write-Output "Downloading DayZ server now..."
	Write-Output "`n"

	#Login to SteamCMD and update DayZ server app
	Start-Process -FilePath "$folder\steamcmd.exe" -ArgumentList ('+login', $steamUs, $steamPw, '+app_update', $steamApp, ' -validate', '+quit') -Wait -NoNewWindow

	Start-Sleep -Seconds 1 
	
	$script:steamUs = $null
	$script:steamPw = $null

	Write-Output "`n"
	Write-Output "DayZ server was updated to latest version"
	Write-Output "`n"
	
}

#Update mods
function ModsUpdate {
	
	#Path to DayZ server folder
	$serverFolder = $folder + $appFolder 
	
	#Check if DayZ server folder exists
	if (!(Test-Path "$serverFolder")) {
		Write-Output "DayZServer folder does not exist! Run server update before mod update."
		Write-Output "`n"
			
	}
	else {
	
		#Check for files with paths to lists of mods
		if (!(Test-Path "$modListPath") -or !(Test-Path "$serverModListPath")) {
			#Check for file with path to list of server mods						
			if (!(Test-Path "$modListPath")) {
				#Prompt user to insert path to list of mods
				$modlist = Read-Host -Prompt 'Insert path to txt file with list of Steam Workshop mods (without quotation marks)'

				Write-Output "`n"
				Write-Output "Selected list is $modlist"
				Write-Output "`n"
									
				#Check that list of mods exists
				if (!(Test-Path "$modlist")) {
					Write-Output "Can't find $modlist !"
					Write-Output "`n"
											
					Menu
				}

				#Prompt user to save path to list of mods for future use
				$saveList = Read-Host -Prompt 'Do you want to save path for future use? (yes/no)'

				if ( ($saveList -eq "yes") -or ($saveList -eq "y")) { 	
					#Create DayZ_Server folder if it doesn't exist
					if (!(Test-Path "$docFolder")) {
						mkdir "$docFolder" >$null
					}
											
					#Save path to list of mods
					$modlist | Set-Content "$modListPath"
											
					Write-Output "Path saved to $modListPath"
					Write-Output "`n"
				}
								
				#Load list of mods from file
				$script:loadMods = Get-Content "$modlist"
			}
						
			#Check for file with path to list of server mods						
			if (!(Test-Path "$serverModListPath")) {
				#Prompt user to insert path to list of server mods
				$serverModList = Read-Host -Prompt 'Insert path to txt file with list of Steam Workshop server mods (without quotation marks)'

				Write-Output "`n"
				Write-Output "Selected list is $serverModList"
				Write-Output "`n"
									
				#Check that list of server mods exists
				if (!(Test-Path "$serverModList")) {
					Write-Output "Can't find $serverModList !"
					Write-Output "`n"
											
					Menu
				}

				#Prompt user to save path to list of server mods for future use
				$saveList = Read-Host -Prompt 'Do you want to save path for future use? (yes/no)'

				if ( ($saveList -eq "yes") -or ($saveList -eq "y")) { 	
					#Create DayZ_Server folder if it doesn't exist
					if (!(Test-Path "$docFolder")) {
						mkdir "$docFolder" >$null
					}
											
					#Save path to list of server mods
					$serverModList | Set-Content "$serverModListPath"
											
					Write-Output "Path saved to $serverModListPath"
					Write-Output "`n"
				}
										
				#Load list of server mods from file
				$script:loadServerMods = Get-Content "$serverModList"
			}
						
		}
		else {
			#Load lists of mods and server mods from files
			$modlist = Get-Content "$modListPath"
			$serverModList = Get-Content "$serverModListPath"
									
			#Check that lists of mods exists
			if (!(Test-Path "$modlist")) {
				Write-Output "Can't find mod list $modlist !"
				Write-Output "`n"
											
				Menu
			}
			elseif (!(Test-Path "$serverModList")) {
				Write-Output "Can't find server mod list $serverModList !"
				Write-Output "`n"
													
				Menu
			}
									
			$script:loadMods = Get-Content "$modlist"
			$script:loadServerMods = Get-Content "$serverModList"
											
			Write-Output "Using stored lists $modlist and $serverModList"
			Write-Output "`n"
											
			#Check that at least one mode exists in one of the lists
			if ((!$loadMods) -and (!$loadServerMods)) {
				Write-Output "Both lists are empty! Add at least one mod to one of the lists!"
				Write-Output "`n"
													
				Menu
			}
		}
					
		$mods = @()
		$wrongId = @()
		$serverMods = @()
		$wrongServerId = @()
					
		#Create lists of correct and wrong format ids
		#For mods
		if ($loadMods) {
			ForEach ($mod in $loadMods) {
				#Regex check for 8+ characters long decimal string which is most likely correct DayZ mod id
				if (($mod -notmatch "[a-zA-Z]") -and ($mod -match "\d{8,}")) {
					$mods += $mod
											
					#Regex check for lines that start with # which serve as comments
				}
				elseif ($mod -match "^[#].*$") {
					#Ignore comments and do nothing
												
					#Other lines are presumed as wrong format id
				}
				else {
					$wrongId += $mod
													
				}
			}
		}
					
		#For server mods					
		if ($loadServerMods) {
			ForEach ($serverMod in $loadServerMods) {
				#Regex check for 8+ characters long decimal string which is most likely correct DayZ mod id
				if (($serverMod -notmatch "[a-zA-Z]") -and ($serverMod -match "\d{8,}")) {
					$serverMods += $serverMod
											
					#Regex check for lines that start with # which serve as comments
				}
				elseif ($serverMod -match "^[#].*$") {
					#Ignore comments and do nothing
												
					#Other lines are presumed as wrong format id
				}
				else {
					$wrongServerId += $serverMod
													
				}
			}
		}
					
		#List wrong format ids
		Write-Output "Following mod ids have wrong format!"
		Write-Output "`n"
		Write-Output "Mods:"
		Write-Output $wrongId
		Write-Output "`n"
		Write-Output "Server mods:"
		Write-Output $wrongServerId
		Write-Output "`n"

		#List correct format ids
		Write-Output "Following mod ids will be used for update:"
		Write-Output "`n"
		Write-Output "Mods:"
		Write-Output $mods
		Write-Output "`n"
		Write-Output "Server mods:"
		Write-Output $serverMods
		Write-Output "`n"

		#Path to SteamCMD DayZ Workshop content folder 
		$workshopFolder = $folder + '\steamapps\workshop\content\221100' 
					
		#Count correct mod ids
		$modCount = $mods.Count
		$serverModCount = $serverMods.Count

		$count = 0 
		$serverCount = 0 

		$updateMods = $null 
		$updateServerMods = $null

		#Temporary command queues for SteamCMD
		$tempList = $null
		$tempListServer = $null
					
		#Remove all loaded mods first
		Remove-Item -Path "$serverFolder\@*" -Recurse -Force

		#Download mods from the list
		if ($loadMods) {
			#Generate command queue for SteamCMD
			foreach ($mod in $mods) { 
				$count++

				if ($count -eq $modCount) {

					$tempList += "workshop_download_item 221100 " + $mod + " validate`r`n" + "quit"

				}
				else {
                                                            
					$tempList += "workshop_download_item 221100 " + $mod + " validate`r`n"

				}
			}
                            
			#Save command queue to temporary file
			$tempList | Set-Content "$tempModList" -Force


			Write-Output "Starting download of $modCount mods..."
			Write-Output "`n"

			#Login to SteamCMD and download/update selected mods
			Start-Process -FilePath "$folder\steamcmd.exe" -ArgumentList ('+login', $steamUs, $steamPw, '+runscript ', "$tempModList") -Wait -NoNewWindow 
									
			Start-Sleep -Seconds 1

			Remove-Item -Path "$tempModList" -Force

		}
                        					
		#Copy downloaded mods to server folder if all previous downloads were succesfull
		if (!((Get-ChildItem $workshopFolder | Measure-Object).Count -eq 0)) { 
							
			#Copy mods from workshop folder to DayZ server folder
			Write-Output "`n"
			Write-Output "Copying mods to DayZ server folder..."
			Write-Output "`n"

			#Copy mods from workshop folder to DayZ server folder and rename them to @modename
			foreach ($mod in $mods) {
				$modLatinName = (Select-String -Path "$workshopFolder\$mod\meta.cpp" -Pattern "name").ToString()
				$modLatinName = '@' + ($modLatinName.split('"')[1].Split([IO.Path]::GetInvalidFileNameChars()) -join '-')
				Copy-Item "$workshopFolder\$mod" -Destination "$serverFolder\$modLatinName" -Recurse
			}
							
			#Copy mod bikeys from mod keys folders to server keys folder
			foreach ($mod in $mods) {
				Copy-Item "$workshopFolder\$mod\keys\*.bikey" -Destination "$serverFolder\keys\"
			}
							
			Write-Output "Selected mods were copied to DayZ server folder"
			Write-Output "`n"
							
			#Check if list of mods for launch parameter exist
			if (!(Test-Path "$modServerPar")) {
				New-Item -Path "$docFolder" -Name "modServerPar.txt" -ItemType file >$null
			}
								
			#Clear old list of mods for launch parameter
			Clear-Content "$modServerPar"
							
			#Create new list of mods for launch parameter
			ForEach ($mod in $mods) {
				[IO.File]::AppendAllText("$modServerPar", "$mod;") >$null
			}
		} 

		#Download Server mods from the list
		if ($loadServerMods) {
			foreach ($serverMod in $serverMods) { 
				$serverCount++

				if ($serverCount -eq $serverModCount) {

					$tempListServer += "workshop_download_item 221100 " + $serverMod + " validate`r`n" + "quit"

				}
				else {
                                                            
					$tempListServer += "workshop_download_item 221100 " + $serverMod + " validate`r`n"

				}
			}

			#Save command queue to temporary file
			$tempListServer | Set-Content "$tempModListServer" -Force


			Write-Output "Starting download of $serverModCount server mods..."
			Write-Output "`n"

			#Login to SteamCMD and download/update selected server mods
			Start-Process -FilePath "$folder\steamcmd.exe" -ArgumentList ('+login', $steamUs, $steamPw, '+runscript ', "$tempModListServer") -Wait -NoNewWindow 
									
			Start-Sleep -Seconds 1 

			Remove-Item -Path "$tempModListServer" -Force

		}
						
		#Copy downloaded server mods to server folder if all previous downloads were succesfull
		if (!((Get-ChildItem $workshopFolder | Measure-Object).Count -eq 0)) { 
							
			#Copy server mods from workshop folder to DayZ server folder
			Write-Output "`n"
			Write-Output "Copying server mods to DayZ server folder..."
			Write-Output "`n"
							
			#Copy server mods from workshop folder to DayZ server folder and rename them to @modename
			foreach ($serverMod in $serverMods) {
				$modLatinName = (Select-String -Path "$workshopFolder\$mod\meta.cpp" -Pattern "name").ToString()
				$modLatinName = '@' + ($modLatinName.split('"')[1].Split([IO.Path]::GetInvalidFileNameChars()) -join '-')
				Copy-Item "$workshopFolder\$mod" -Destination "$serverFolder\$modLatinName" -Recurse
			}

			#Copy mod bikeys from mod keys folders to server keys folder
			foreach ($serverMod in $serverMods) {
				Copy-Item "$serverFolder\$serverMod\keys\*.bikey" -Destination "$serverFolder\keys\"
			}
							
			Write-Output "Selected server mods were copied to DayZ server folder"
			Write-Output "`n"
							
			#Check if list of server mods for launch parameter exist
			if (!(Test-Path "$serverModServerPar")) {
				New-Item -Path "$docFolder" -Name "serverModServerPar.txt" -ItemType file >$null
			}
								
			#Clear old list of server mods for launch parameter
			Clear-Content "$serverModServerPar"
							
			#Create new list of server mods for launch parameter
			ForEach ($serverMod in $serverMods) {
				[IO.File]::AppendAllText("$serverModServerPar", "$serverMod;") >$null
			}
		}

		$script:steamUs = $null
		$script:steamPw = $null 

	}
}

#Run DayZ server with mods
function Server_menu {

	#Reload file with path to launch parameters in case it was manually changed without script restart
	$userServerParPath = $docFolder + '\userServerParPath.txt'
	
	#Path to server folder
	$serverFolder = $folder + $appFolder
	
	#Prepare empty variables for lists of mod ids
	$modsServer = $null
	$serverModsServer = $null
	
	#Check if list of mods for launch parameter exist
	if (Test-Path "$modServerPar") {
		#Get list of mod ids for -mod= launch parameter
		$modsServer = Get-Content "$modServerPar" -Raw
	}
		
	if (Test-Path "$serverModServerPar") {
		#Get list of mod ids for -serverMod= launch parameter
		$serverModsServer = Get-Content "$serverModServerPar" -Raw
	}
		
	#Check if DayZ server exe exists
	if (!(Test-Path "$serverFolder")) {
		Write-Output "DayZServer folder does not exist in $serverFolder ! Run server update to download/repair server data."
		Write-Output "`n"
			
	}
	else {
	
		switch ($select) {
			#Start server menu
			$null {
				Write-Output "Start server menu:"
				Write-Output "1) Use user launch parameters"
				Write-Output "2) Use default launch parameters"
				Write-Output "3) Return to previous menu"
				Write-Output "`n"

				$select = Read-Host -Prompt 'Please select desired action from menu above'

				Server_menu

				Break
			}
                            
			#Use user provided server parameters
			1 {
				Write-Output "`n"
				Write-Output "User launch parameters selected"
				Write-Output "`n"
							
				#Check for file with user server launch parameters
				if (!(Test-Path "$userServerParPath")) {
					#Prompt user to insert path to file with user server launch parameters
					$serverParPath = Read-Host -Prompt 'Insert path to file with user launch parameters (without quotation marks)'

					Write-Output "`n"
					Write-Output "Selected file is $serverParPath"
					Write-Output "`n"
									
					#Check that file with launch parameters exists
					if (!(Test-Path "$serverParPath")) {
						Write-Output "Can't find $serverParPath !"
						Write-Output "`n"
											
						Menu
					}

					#Prompt user to save path to file with user server launch parameters for future use
					$savePath = Read-Host -Prompt 'Do you want to save path for future use? (yes/no)'

					if ( ($savePath -eq "yes") -or ($savePath -eq "y")) { 	
						#Create DayZ_Server folder if it doesn't exist
						if (!(Test-Path "$docFolder")) {
							mkdir "$docFolder" >$null
						}
											
						#Save path to file with user server launch parameters
						$serverParPath | Set-Content "$userServerParPath"
											
						Write-Output "`n"
						Write-Output "Path saved to $userServerParPath"
						Write-Output "`n"
					}
				}
				else {
					#Use saved path to file with user server launch parameters
					$serverParPath = Get-Content "$userServerParPath"
											
					Write-Output "Selected file with user launch parameters is $serverParPath"
					Write-Output "`n"
											
				}
								
				#Load user server launch parameters
				$serverPar = Get-Content "$serverParPath" -Raw
								
				#Check if user server launch parameters were properly loaded
				if (!$serverPar) {
					Write-Output "Server launch parameter file is empty or wasn't loaded properly!"
					Write-Output "`n"
									
					#Return to Main menu if it wasn't started from CMD			
					if (($s -eq "") -and ($server -eq "")) { 
						$select = $null

						return
					}
										
					exit 0
				}
								
				Write-Output "Launching DayZ server with user launch parameters..."
				Write-Output "`n"
									
				#Run server
				$procServer = Start-Process -FilePath "$serverFolder\DayZServer_x64.exe" -PassThru -ArgumentList "`"-bepath=$serverFolder\battleye`" $serverPar"
										
				#Save server PID for future use
				$procServer.id | Add-Content "$pidServer"
										
				Start-Sleep -Seconds 5	
										
				Write-Output "DayZ server is up and running..."
				Write-Output "`n"

				Break
			}
                            
			#Use default server parameters
			2 {
				Write-Output "`n"
				Write-Output "Default launch parameters selected"
				Write-Output "`n"
										
				Write-Output "Launching DayZ server with default launch parameters..."
				Write-Output "`n"

				#Run server
				$procServer = Start-Process -FilePath "$serverFolder\DayZServer_x64.exe" -PassThru -ArgumentList "`"-config=$serverFolder\serverDZ.cfg`" `"-mod=$modsServer`" `"-serverMod=$serverModsServer`" `"-bepath=$serverFolder\battleye`" `"-profiles=$serverFolder\logs`" -port=2302 -freezecheck -adminlog -dologs"
										
				#Save server PID for future use
				$procServer.id | Add-Content "$pidServer"
										
				Start-Sleep -Seconds 5	
										
				Write-Output "DayZ server is up and running..."
				Write-Output "`n"

				Break
			}

			#Return to previous menu
			3 {
				Menu

				Break
			}
                            
			#Force user to select one of provided options
			Default {
				Write-Output "`n"
				Write-Output "Select number from provided list (1-3)"
				Write-Output "`n"
															
				$select = $null
															
				Server_menu
			}
		}
	}               
}

#Stop running DayZ server
function ServerStop {
	
	#Get previously started DayZ server PIDs from the list
	$loadPID = Get-Content "$pidServer"
	
	#Check if PID list is not empty
	if (!$loadPID) {
		Write-Output "There is no process ID in list! No DayZ server instance is running or it wasn't started by this script."
		Write-Output "`n"
			
	}
	else {
		#Try every process id in list
		foreach ($proc in $loadPID) {
			#Get process id of DayZ server instance
			$killServer = Get-Process -Id $proc 2>$null
							
			#Check for running DayZ server instance
			if (!$killServer) {
				Write-Output "DayZ server instance with PID $proc is not running!"
				Write-Output "`n"
								
				#Kill server
			}
			else { 
				Write-Output "DayZ server with PID $proc found, commencing shutdown..."
				Write-Output "`n"
									
				#Gracefull exit
				$killServer.CloseMainWindow() >$null
											
				#Force exit after five seconds
				Start-Sleep -Seconds 5
											
				if (!$killServer.HasExited) {
					$killServer | Stop-Process -Force
													
					Write-Output "DayZ server with PID $proc was forcefully turned off"
					Write-Output "`n"
													
				}
												
				Write-Output "DayZ server with PID $proc was turned off"
				Write-Output "`n"
											
			}
		}
					
		#Clear PID list
		Clear-Content "$pidServer" -Force	
	}
}

#Uninstall DayZ server
function ServerUninstall {
	
	Write-Output "Uninstalling DayZ server now..."
	Write-Output "`n"

	$serverFolder = $folder + $appFolder
														
	#Uninstall DayZ server
	Start-Process -FilePath "$folder\steamcmd.exe" -ArgumentList ('+app_uninstall -complete ', $steamApp, '+quit') -Wait -NoNewWindow 
																											
	Start-Sleep -Seconds 1
    
	#Check if server was deleted and if not removed it forcefully
	if (Test-Path "$serverFolder") {
		Remove-Item -Path "$serverFolder" -Recurse -Force
	}
	
	if (Test-Path "$serverFolder") {   																																				
		Write-Output "`n"
		Write-Output "DayZ server uninstallation was unsuccessful"
		Write-Output "`n"

	}
	else {
		Write-Output "`n"
		Write-Output "DayZ server was succesfully uninstalled"
		Write-Output "`n"

	}
}

#Uninstall/remove DayZ Server/saved info
function Remove_menu {

	Write-Output "Remove menu:"
	Write-Output "1) Remove Steam login"
	Write-Output "2) Remove path to SteamCMD folder"
	Write-Output "3) Remove path to mod list file"
	Write-Output "4) Remove mod"
	Write-Output "5) Remove path to user launch parameters file"
	Write-Output "6) Uninstall DayZ server"
	Write-Output "7) Uninstall SteamCMD"
	Write-Output "8) Return to previous menu"
	Write-Output "`n"

	$select = Read-Host -Prompt 'Please select desired action from menu above'
	
	switch ($select) {
		#Remove encrypted Steam login files
		1 {
			Write-Output "`n"
			Write-Output "Remove Steam login selected"
			Write-Output "`n"
			
			#Path to encrypted Steam login files
			Remove-Item "$docFolder\SteamLog*.txt"
			
			Write-Output "Stored Steam login was removed"
			Write-Output "`n"
			
			Remove_menu

			Break
		}

		#Remove stored path to SteamCMD folder
		2 {
			Write-Output "`n"
			Write-Output "Remove path to SteamCMD folder selected"
			Write-Output "`n"
						
			#Path to file with stored path to SteamCMD folder
			Remove-Item "$docFolder\SteamCmdPath.txt"
						
			Write-Output "Stored path to SteamCMD folder was removed"
			Write-Output "`n"
						
			Remove_menu

			Break
		}

		#Remove stored path to mod list file
		3 {
			Write-Output "`n"
			Write-Output "Remove path to mod list file selected"
			Write-Output "`n"
								
			Write-Output "Remove mod list menu:"
			Write-Output "1) Remove mod list"
			Write-Output "2) Remove server mod list"
			Write-Output "3) Remove both mod and server mod lists"
			Write-Output "4) Return to previous menu"
			Write-Output "`n"
								
			#Prompt user for mod list selection
			$rem_list = Read-Host -Prompt 'Please select desired action from menu above'
																
			Write-Output "`n"	
														
			if ($rem_list -eq '1') { 	
				if (Test-Path "$docFolder\modListPath.txt") {
					#Path to file with stored path to mod list file
					Remove-Item "$docFolder\modListPath.txt"
				}
											
				Write-Output "Stored path to mod list file was removed"
				Write-Output "`n"
										
			}
			elseif ($rem_list -eq '2') {
				if (Test-Path "$docFolder\serverModListPath.txt") {
					#Path to file with stored path to server mod list file
					Remove-Item "$docFolder\serverModListPath.txt"
				}
													
				Write-Output "Stored path to server mod list file was removed"
				Write-Output "`n"
										
			}
			elseif ($rem_list -eq '3') {
				#Files with paths to both mod and server mod file lists
				if (Test-Path "$docFolder\modListPath.txt") {
					#Path to file with stored path to mod list file
					Remove-Item "$docFolder\modListPath.txt"
				}
																
				if (Test-Path "$docFolder\serverModListPath.txt") {
					#Path to file with stored path to server mod list file
					Remove-Item "$docFolder\serverModListPath.txt"
				}
																
				Write-Output "Stored paths to mod and server mod list files were removed"
				Write-Output "`n"
																
			}
			elseif ($rem_list -eq '4') { 
				#Return to previous menu
				Remove_menu
																		
			}
								
			Remove_menu

			Break
		}

		#Select mod and remove it
		4 {
			$reminder = $false
                    
			Write-Output "`n"
			Write-Output "Remove mod selected"
			Write-Output "`n"
										
			SteamCMDFolder
										
			#Path to SteamCMD DayZ Workshop content folder 
			$workshopFolder = $folder + '\steamapps\workshop\content\221100' 

			#Path to DayZ server folder
			$serverFolder = $folder + $appFolder
										
			#Prompt user to insert path to SteamCMD folder
			$rem_mod = Read-Host -Prompt 'Insert mod id you wish to remove'
										
			#Check if mod id was really inserted
			if ($rem_mod -eq "") {
				Write-Output "`n"
				Write-Output "No mod id inserted! Returning to Remove menu..."
				Write-Output "`n"
												
				Remove_menu
			}
										
			Write-Output "`n"
										
			#Check if selected mod folder exist in workshop folder
			if (!(Test-Path "$workshopFolder\$rem_mod")) {
				Write-Output "Selected mod folder doesn't exist in $workshopFolder !"
				Write-Output "`n"
												
			}
			else { 
				#Remove selected mod folder from workshop folder
				Remove-Item -LiteralPath "$workshopFolder\$rem_mod" -Force -Recurse
														
				Write-Output "Selected mod folder was removed from $workshopFolder"
				Write-Output "`n"

				$reminder = $true
			}
													
			#Check if selected mod folder exist in DayZ server folder
			if (!(Test-Path "$serverFolder\$rem_mod")) {
				Write-Output "Selected mod folder doesn't exist in $serverFolder !"
				Write-Output "`n"
												
			}
			else { 
				#Remove selected mod folder from DayZ server folder
				Remove-Item -LiteralPath "$serverFolder\$rem_mod" -Force -Recurse
														
				Write-Output "Selected mod folder was removed from $serverFolder"
				Write-Output "`n"

				$reminder = $true
			}
										
			#Remove selected mod id from mod and server mode lists
			if (Test-Path "$modServerPar") {
				$loadModList = Get-Content "$modServerPar" | ForEach-Object { $_ -replace "($rem_mod;)", "" }
				$loadModList | Set-Content "$modServerPar"
												
			} 
											
			if (Test-Path "$serverModServerPar") { 
				$loadServerModList = Get-Content "$serverModServerPar" | ForEach-Object { $_ -replace "($rem_mod;)", "" }
				$loadServerModList | Set-Content "$serverModServerPar"
			}
					
			if ($reminder) { 
				Write-Output "Don't forget to remove $rem_mod also from your list of mods/server mods in case you don't want to use it anymore!"
				Write-Output "`n"
			}
										
			Remove_menu

			Break
		}

		#Remove stored path to user launch parameters file
		5 {
			Write-Output "`n"
			Write-Output "Remove path to user launch parameters file selected"
			Write-Output "`n"
								
			#Path to file with stored path to mod list file
			Remove-Item "$docFolder\userServerParPath.txt"
												
			Write-Output "Stored path to user launch parameters file was removed"
			Write-Output "`n"
												
			Remove_menu

			Break
		}

		#Uninstall DayZ server
		6 {
			Write-Output "`n"
			Write-Output "Uninstall DayZ server selected"
			Write-Output "`n"
														
			#Prompt user for DayZ server uninstall confirmation
			$rem_server = Read-Host -Prompt 'Are you sure you want to uninstall DayZ server? (yes/no)'
														
			Write-Output "`n"	
														
			if ( ($rem_server -eq "yes") -or ($rem_server -eq "y")) { 	
				SteamCMDFolder
				SteamCMDExe
				ServerUninstall
																
			}
														
			Remove_menu

			Break
		}

		#Uninstall SteamCMD
		7 {
			Write-Output "`n"
			Write-Output "Uninstall SteamCMD selected"
			Write-Output "`n"
																
			#Prompt user for SteamCMD uninstall confirmation
			$rem_server = Read-Host -Prompt 'Are you sure you want to uninstall SteamCMD? This option will also uninstall DayZ server and remove all its data! (yes/no)'
																
			Write-Output "`n"	
														
			if ( ($rem_server -eq "yes") -or ($rem_server -eq "y")) { 	
				SteamCMDFolder
				SteamCMDExe
				ServerUninstall
																		
				Write-Output "Uninstalling SteamCMD now..."
				Write-Output "`n"
																		
				Remove-Item -LiteralPath "$folder" -Force -Recurse
																		
				Write-Output "SteamCMD was succesfully uninstalled"
				Write-Output "`n"
																		
			}
																
			#Prompt user for Documents folder removal confirmation
			$rem_mod = Read-Host -Prompt 'Do you want to remove Documents folder which contains all saved folder/exe paths, mod and SteamCMD login info from Documents? (yes/no)'
																
			Write-Output "`n"	
														
			if ( ($rem_mod -eq "yes") -or ($rem_mod -eq "y")) { 	
				Write-Output "Removing Documents folder now..."
				Write-Output "`n"
																		
				Remove-Item -LiteralPath "$docFolder" -Force -Recurse
																		
				Write-Output "Folder was succesfully removed"
				Write-Output "`n"
																		
			}
																
			Remove_menu

			Break
		}

		#Return to previous menu
		8 {
			Menu

			Break
		}

		#Force user to select one of provided options
		Default {
			Write-Output "`n"
			Write-Output "Select number from provided list (1-7)"
			Write-Output "`n"
																				
			Remove_menu
		}

	}

}

#When launch parameters are used
#Parameters are described in readme.txt
function CMD {
	
	#Prepare variables for correct parameter value check
	$paramCheckUpdate = $false
	$paramCheckServer = $false
	
	Write-Output "`n"
	Write-Output "Launch parameters are being used."

	#Set Steam app id and server folder name
	if ($app -eq "exp") { 
		Write-Output "`n"
		Write-Output "Experimental server management selected"
		Write-Output "`n"
                    
		#Set Experimental app id
		$steamApp = 1042420
                    
		#Set Experimental app folder
		$appFolder = '\steamapps\common\DayZ Server Exp'

	}
	else {

		Write-Output "`n"
		Write-Output "Stable server management selected"
		Write-Output "`n"
                    
		#Set Stable app id
		$steamApp = 223350
                    
		#Set Stable app folder
		$appFolder = '\steamapps\common\DayZServer'

	}
	
	#Call server update and related functions
	if (($u -eq "server") -or ($update -eq "server")) { 
		Write-Output "`n"
		Write-Output "Server update selected"
		Write-Output "`n"
			
		$select = 1
			
		SteamCMDFolder
		SteamCMDExe
		SteamLogin
				
		$paramCheckUpdate = $true
				
			
		#Call mods update and related functions		
	}
	elseif (($u -eq "mod") -or ($u -eq "mods") -or ($update -eq "mod") -or ($update -eq "mods")) { 
		Write-Output "`n"
		Write-Output "Mods update selected"
		Write-Output "`n"
						
		$select = 2
						
		SteamCMDFolder
		SteamCMDExe
		SteamLogin
							
		$paramCheckUpdate = $true
							
						
		#Call both server and mods updates 
	}
	elseif (($u -eq "all") -or ($update -eq "all")) { 
		Write-Output "`n"
		Write-Output "Server + mod update selected"
		Write-Output "`n"
									
		#Server update
		$select = 1
			
		SteamCMDFolder
		SteamCMDExe
		SteamLogin
									
		#Mods update
		$select = 2
									
		SteamLogin
									
		$paramCheckUpdate = $true
									
	}
	#Start DayZ server							
	if (($s -eq "start") -or ($server -eq "start")) { 
		Write-Output "`n"
								
		SteamCMDFolder
			
		$paramCheckServer = $true
			
		#Check which launch parameter file to use
		#User launch parameters
		if (($lp -eq "user") -or ($launchParam -eq "user")) { 
			Write-Output "Start server with user launch parameters selected"
					
			$select = 1
					
			Server_menu
					
			#Default launch parameters
		}
		else {
			Write-Output "Start server with default launch parameters selected"
								
			$select = 2
					
			Server_menu
		}
				
		#Stop running server	
	}
	elseif (($s -eq "stop") -or ($server -eq "stop")) { 	
		Write-Output "`n"
		Write-Output "Stop running server selected"
		Write-Output "`n"
										
		ServerStop
						
		$paramCheckServer = $true

	}

	#Check for wrong launch parameter values
	if (($paramCheckUpdate -eq $false) -or ($paramCheckServer -eq $false)) { 
		if ((($paramCheckUpdate -eq $false) -and !($u -eq "")) -or (($paramCheckUpdate -eq $false) -and !($update -eq ""))) { 
			Write-Output "`n"
			Write-Output "Wrong -u/-update parameter value used! Check readme.txt or 'Get-Help .\Server_manager.ps1 -Parameter update' for correct lauch parameter values."
			Write-Output "`n"
		}
				
		if ((($paramCheckServer -eq $false) -and !($s -eq "")) -or (($paramCheckServer -eq $false) -and !($server -eq ""))) { 
			Write-Output "`n"
			Write-Output "Wrong -s/-server parameter value used! Check readme.txt or 'Get-Help .\Server_manager.ps1 -Parameter server' for correct lauch parameter values."
			Write-Output "`n"
		}
			
		exit 0
	}
			
	Write-Output "All selected tasks are done."
	Write-Output "`n"
	
	exit 0
}


function MainMenu {


	Write-Output "`n"
	Write-Output "Welcome to DayZ server/mods management app!"

	Write-Output "`n"
	Write-Output "Menu:"
	Write-Output "1) Stable server management"
	Write-Output "2) Experimental server management"
	Write-Output "3) Exit"
	Write-Output "`n"

	$select = Read-Host -Prompt 'Please select desired action from menu above'
	
	switch ($select) {
		#Steam Stable server app
		1 {
			Write-Output "`n"
			Write-Output "Stable server app selected"
			Write-Output "`n"
                    
			#Set Stable app id
			$steamApp = 223350
                    
			#Set Stable app folder
			$appFolder = '\steamapps\common\DayZServer'
			
			Menu

			Break
		} 

		#Steam Experimental server app
		2 {
			Write-Output "`n"
			Write-Output "Experimental server app selected"
			Write-Output "`n"
                    
			#Set Experimental app id
			$steamApp = 1042420

			#Set Experimental app folder
			$appFolder = '\steamapps\common\DayZ Server Exp'
						
			Menu

			Break
		}

		#Close script
		3 {
			Write-Output "`n"
			Write-Output "Exit selected"
			Write-Output "`n"
														
			exit 0

			Break
		}

		#Force user to select one of provided options
		Default {
			Write-Output "`n"
			Write-Output "Select number from provided list (1-3)"
			Write-Output "`n"
																				
			MainMenu
		}
	}
}

#Open Main menu if launch parameters are not used
if (($u -eq "") -and ($update -eq "") -and ($s -eq "") -and ($server -eq "")) {    
	MainMenu

}
else {
	#Run CMD function when launch parameters are used
	CMD

}

exit 0
