-- List all folders in Apple Notes (iCloud account)
-- Usage: osascript list_folders.applescript

tell application "Notes"
	set icloudAccount to missing value
	repeat with a in every account
		if name of a is "iCloud" then
			set icloudAccount to a
			exit repeat
		end if
	end repeat

	if icloudAccount is missing value then
		return "Error: iCloud account not found in Notes."
	end if

	set output to "iCloud Notes Folders (syncs to iPhone):" & linefeed & linefeed
	repeat with f in every folder of icloudAccount
		set folderName to name of f
		set noteCount to count of every note of f
		set output to output & "  " & folderName & " (" & noteCount & " notes)" & linefeed
	end repeat
	return output
end tell
