Sub HighlightCellsMatchingRegex()
    Dim ws As Worksheet
    Dim rng As Range
    'Dim cell As Range
    Dim regexPattern As String
    Dim regex As Object
    Dim isMatch As Boolean
    Dim lastRow As Long

    
    ' Set the worksheet and range to target
    Set ws = ThisWorkbook.Worksheets("Z_RMW_QUALIFIERS") ' Replace "Sheet1" with your actual worksheet name
    ' Find the last row with data in column P
    lastRow = ws.Cells(ws.Rows.Count, "P").End(xlUp).Row
    
    ' Set cell to 1
    ' cell = 1
    
    ' Set the range from cell P1 to the last cell in column P
    Set rng = ws.Range("P1:P" & lastRow)
    'Set rng = ws.Range("P:P") ' Replace "P:P" with the actual column range you want to target
    
    ' Set the regular expression pattern
    'regexPattern = "[G,M,N,P]\d{2}\s"
    regexPattern = "[G,M,N,P](\d{2})(\s|\,)|(\s?|\,)^[G,M,N,P](\s|\,)|[A-Z](\s)THRU"
    
    ' Create a regular expression object
    Set regex = CreateObject("VBScript.RegExp")
    regex.Pattern = regexPattern
    
    ' Loop through each cell in the range
    For Each rng In rng
        ' Check if the cell value matches the regular expression pattern
        isMatch = regex.Test(rng.Value)
        
        ' If the cell value matches, then highlight the cell with light green color
        If isMatch Then
            rng.Interior.Color = RGB(204, 255, 204) ' Light green color
        Else
            ' If the cell value doesn't match, clear any existing color
            rng.Interior.ColorIndex = xlNone
        End If
    Next rng
    
    ' Clean up the regular expression object
    Set regex = Nothing
End Sub
