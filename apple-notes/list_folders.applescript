-- List all folders in Apple Notes
-- Usage: osascript list_folders.applescript

tell application "Notes"
	set output to "Apple Notes Folders:" & linefeed & linefeed
	repeat with f in every folder
		set folderName to name of f
		set noteCount to count of every note of f
		set output to output & "  " & folderName & " (" & noteCount & " notes)" & linefeed
	end repeat
	return output
end tell
