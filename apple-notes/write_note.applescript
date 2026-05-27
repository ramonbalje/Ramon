-- Create or update a note in Apple Notes (iCloud account for iPhone sync)
-- Usage: osascript write_note.applescript "Title" "Body" ["Folder Name"]

on run argv
	if (count of argv) < 2 then
		return "Error: Usage: osascript write_note.applescript \"Title\" \"Body\" [\"Folder Name\"]"
	end if

	set noteTitle to item 1 of argv
	set noteBody to item 2 of argv
	set folderName to "Notes"
	if (count of argv) > 2 then
		set folderName to item 3 of argv
	end if

	tell application "Notes"
		-- Target iCloud account so note syncs to iPhone
		set icloudAccount to missing value
		repeat with a in every account
			if name of a is "iCloud" then
				set icloudAccount to a
				exit repeat
			end if
		end repeat

		if icloudAccount is missing value then
			return "Error: iCloud account not found in Notes. Make sure iCloud Notes is enabled in System Settings."
		end if

		-- Find or create the target folder inside iCloud account
		set targetFolder to missing value
		repeat with f in every folder of icloudAccount
			if name of f is folderName then
				set targetFolder to f
				exit repeat
			end if
		end repeat
		if targetFolder is missing value then
			set targetFolder to make new folder at icloudAccount with properties {name: folderName}
		end if

		-- Check if a note with the same title already exists
		set existingNote to missing value
		repeat with n in every note of targetFolder
			if name of n is noteTitle then
				set existingNote to n
				exit repeat
			end if
		end repeat

		if existingNote is not missing value then
			set body of existingNote to noteBody
			return "Updated note: " & noteTitle & " in iCloud folder: " & folderName
		else
			make new note at targetFolder with properties {name: noteTitle, body: noteBody}
			return "Created note: " & noteTitle & " in iCloud folder: " & folderName
		end if
	end tell
end run
