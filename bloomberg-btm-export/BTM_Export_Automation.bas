Attribute VB_Name = "BTM_Export_Automation"
Option Explicit

' =====================================================================
' BTM date change -> export to Excel -> copy into master workbook
'
' Add this module to a workbook (e.g. your master/target workbook),
' then run RunFullBTMWorkflow. See README.md in this folder for setup
' and calibration steps - the two Private subs marked "CALIBRATE THIS"
' depend on your specific BTM screen layout and must be adjusted by
' watching what keystrokes you actually use.
' =====================================================================

' --- Configuration: adjust to your setup ---
Private Const BBG_WINDOW_TITLE As String = "Bloomberg"   ' partial title of the Bloomberg Terminal window
Private Const TARGET_SHEET_NAME As String = "Data"        ' sheet in THIS workbook to paste imported data into
Private Const TARGET_START_CELL As String = "A1"          ' top-left cell to paste into
Private Const WAIT_FOR_EXPORT_SECONDS As Long = 20         ' how long to wait for the Bloomberg export workbook to appear

Public Sub RunFullBTMWorkflow()
    Dim newDateStr As String
    newDateStr = InputBox("Enter the new date for BTM (in the format your screen expects, e.g. MM/DD/YY):", _
                           "BTM Date", Format(Date, "mm/dd/yy"))
    If newDateStr = "" Then Exit Sub

    If Not ActivateBloombergTerminal() Then
        MsgBox "Could not find/activate the Bloomberg Terminal window." & vbCrLf & _
               "Adjust BBG_WINDOW_TITLE to match your window's title.", vbExclamation
        Exit Sub
    End If

    SetBTMDate newDateStr
    ExportCurrentScreenToExcel
    ImportLatestBloombergExport TARGET_SHEET_NAME, TARGET_START_CELL

    MsgBox "Done - data imported into '" & TARGET_SHEET_NAME & "'.", vbInformation
End Sub

Private Function ActivateBloombergTerminal() As Boolean
    On Error Resume Next
    AppActivate BBG_WINDOW_TITLE, True
    ActivateBloombergTerminal = (Err.Number = 0)
    On Error GoTo 0
End Function

Private Sub SetBTMDate(ByVal newDateStr As String)
    ' *** CALIBRATE THIS ***
    ' Record the exact keystrokes you use manually to reach BTM's date field:
    ' number of Tabs/clicks, or a direct hotkey your screen supports.
    ' The pattern below (tab to field, select-all, type, Enter/<GO>) is a
    ' common starting point but WILL need adjusting for your screen.

    Application.Wait Now + TimeSerial(0, 0, 1)   ' let window focus settle
    SendKeys "{TAB 3}", True                      ' <-- adjust: Tabs needed to reach the date field
    SendKeys "^a", True                           ' select existing value
    SendKeys newDateStr, True
    SendKeys "{ENTER}", True                      ' <GO>
    Application.Wait Now + TimeSerial(0, 0, 2)
End Sub

Private Sub ExportCurrentScreenToExcel()
    ' *** CALIBRATE THIS ***
    ' BTM's "export to Excel" is usually triggered by clicking the small
    ' spreadsheet icon in the top-right of the screen, or via right-click >
    ' Export - there is no single keyboard shortcut across all Bloomberg
    ' screens. If yours has one, replace the MsgBox below with e.g.:
    '   SendKeys "%{F1}", True   ' EXAMPLE ONLY - use your screen's real shortcut

    MsgBox "Trigger Bloomberg's 'Export to Excel' now (icon/right-click menu), then click OK to continue.", _
           vbInformation, "Manual export step"
End Sub

Public Sub ImportLatestBloombergExport(Optional ByVal targetSheet As String = TARGET_SHEET_NAME, _
                                        Optional ByVal targetCell As String = TARGET_START_CELL)
    ' Bloomberg's Excel export typically opens a NEW workbook in this same
    ' Excel instance (rather than saving a file to disk). This finds that
    ' workbook, copies its data into this workbook, then closes it.

    Dim wb As Workbook, src As Workbook
    Dim thisWb As Workbook
    Set thisWb = ThisWorkbook

    Dim deadline As Date
    deadline = Now + TimeSerial(0, 0, WAIT_FOR_EXPORT_SECONDS)

    Do
        For Each wb In Application.Workbooks
            If Not wb Is thisWb Then
                If wb.Name Like "Book*" Or InStr(1, wb.Name, "Bloomberg", vbTextCompare) > 0 Then
                    Set src = wb
                    Exit For
                End If
            End If
        Next wb
        If Not src Is Nothing Then Exit Do
        DoEvents
    Loop While Now < deadline

    If src Is Nothing Then
        MsgBox "Timed out waiting for the Bloomberg export workbook to appear." & vbCrLf & _
               "If Bloomberg instead saves a file to disk, use ImportFromExportFolder instead.", vbExclamation
        Exit Sub
    End If

    Dim srcRange As Range
    Set srcRange = src.Worksheets(1).UsedRange

    Dim destWs As Worksheet
    Set destWs = thisWb.Worksheets(targetSheet)
    destWs.Range(targetCell).Resize(srcRange.Rows.Count, srcRange.Columns.Count).Value = srcRange.Value

    src.Close SaveChanges:=False
End Sub

' --- Alternative: use this instead of ImportLatestBloombergExport if your
' Bloomberg export actually writes a file to a folder (e.g. Desktop or a
' "Bloomberg Exports" folder) rather than opening a new workbook. ---
Public Sub ImportFromExportFolder(ByVal folderPath As String, _
                                   Optional ByVal targetSheet As String = TARGET_SHEET_NAME, _
                                   Optional ByVal targetCell As String = TARGET_START_CELL)
    Dim fso As Object, fileName As String, latestFile As String, latestDate As Date
    Set fso = CreateObject("Scripting.FileSystemObject")

    fileName = Dir(folderPath & "\*.xls*")
    Do While fileName <> ""
        Dim fullPath As String
        fullPath = folderPath & "\" & fileName
        If FileDateTime(fullPath) > latestDate Then
            latestDate = FileDateTime(fullPath)
            latestFile = fullPath
        End If
        fileName = Dir()
    Loop

    If latestFile = "" Then
        MsgBox "No Excel files found in " & folderPath, vbExclamation
        Exit Sub
    End If

    Dim src As Workbook
    Set src = Workbooks.Open(latestFile, ReadOnly:=True)

    Dim srcRange As Range
    Set srcRange = src.Worksheets(1).UsedRange

    Dim destWs As Worksheet
    Set destWs = ThisWorkbook.Worksheets(targetSheet)
    destWs.Range(targetCell).Resize(srcRange.Rows.Count, srcRange.Columns.Count).Value = srcRange.Value

    src.Close SaveChanges:=False
End Sub
