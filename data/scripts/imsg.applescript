on run argv
	set isRunning to is_running("Messages")
	if not isRunning then
	  tell application "Messages" to launch
	  delay 2
	end if

	set tobuddy to first item of argv
	set type to second item of argv

	if (type = "message") then
		set message to third item of argv
	else if type = "attachment"	
		set attach to third item of argv
		set message to POSIX file attach
	else
		exit
	end if

	tell application "Messages"

		send message to buddy tobuddy of (service 1 whose service type is iMessage)

		tell application "System Events"
			set visible of process "Messages" to false
		end tell	

	end tell

end run

on is_running(appName)
	tell application "System Events" to (name of processes) contains appName
end is_running