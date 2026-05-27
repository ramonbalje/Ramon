-- Read notes from Apple Notes (iCloud account)
-- Usage: osascript read_notes.applescript
-- Optional: osascript read_notes.applescript "Folder Name"

on run argv
	set folderFilter to ""
	if (count of argv) > 0 then
		set folderFilter to item 1 of argv
	end if

	tell application "Notes"
		-- Target iCloud account
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

		set allNotes to {}
		if folderFilter is "" then
			set allNotes to every note of icloudAccount
		else
			repeat with f in every folder of icloudAccount
				if name of f is folderFilter then
					set allNotes to every note of f
					exit repeat
				end if
			end repeat
		end if

		set output to ""
		repeat with n in allNotes
			set noteTitle to name of n
			set noteBody to plaintext of n
			set modDate to modification date of n

			set output to output & "=== " & noteTitle & " ===" & linefeed
			set output to output & "Modified: " & (modDate as string) & linefeed
			set output to output & noteBody & linefeed
			set output to output & linefeed & "---" & linefeed & linefeed
		end repeat

		if output is "" then
			return "No notes found."
		end if
		return output
	end tell
end run
