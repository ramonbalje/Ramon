-- Delete a note by title from Apple Notes
-- Usage: osascript delete_note.applescript "Title" ["Folder Name"]

on run argv
	if (count of argv) < 1 then
		return "Error: Usage: osascript delete_note.applescript \"Title\" [\"Folder Name\"]"
	end if

	set noteTitle to item 1 of argv
	set folderName to ""
	if (count of argv) > 1 then
		set folderName to item 2 of argv
	end if

	tell application "Notes"
		set targetNote to missing value

		if folderName is not "" then
			try
				set targetNote to first note of folder folderName whose name is noteTitle
			end try
		else
			repeat with n in every note
				if name of n is noteTitle then
					set targetNote to n
					exit repeat
				end if
			end repeat
		end if

		if targetNote is missing value then
			return "Error: Note not found: " & noteTitle
		end if

		delete targetNote
		return "Deleted note: " & noteTitle
	end tell
end run
