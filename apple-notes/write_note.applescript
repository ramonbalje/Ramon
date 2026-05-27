-- Create or update a note in Apple Notes
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
		-- Find or create the target folder
		if folderName is not "Notes" then
			set targetFolder to missing value
			repeat with f in every folder
				if name of f is folderName then
					set targetFolder to f
					exit repeat
				end if
			end repeat
			if targetFolder is missing value then
				set targetFolder to make new folder with properties {name: folderName}
			end if
		else
			set targetFolder to folder "Notes"
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
			-- Update existing note
			set body of existingNote to noteBody
			return "Updated note: " & noteTitle & " in folder: " & folderName
		else
			-- Create new note
			make new note at targetFolder with properties {name: noteTitle, body: noteBody}
			return "Created note: " & noteTitle & " in folder: " & folderName
		end if
	end tell
end run
