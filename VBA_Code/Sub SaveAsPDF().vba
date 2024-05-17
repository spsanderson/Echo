Sub SaveAsPDF()
    Dim ws As Worksheet
    Dim rng As Range
    Dim pdfPath As String
    Dim lastRow As Long
    Dim i As Long

    ' Set the worksheet and range
    Set ws = ThisWorkbook.Sheets(1) ' Adjust if the sheet is not the first one
    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row

    ' Sort the data by Database and then by Project
    ws.Range("A1:D" & lastRow).Sort key1:=ws.Range("A2"), Order1:=xlAscending, key2:=ws.Range("C2"), Order2:=xlAscending, Header:=xlYes

    ' Create a temporary sheet for formatting
    Dim tempSheet As Worksheet
    Set tempSheet = ThisWorkbook.Sheets.Add
    tempSheet.Name = "TempSheet"

    ' Set headers
    tempSheet.Cells(1, 1).Value = "Database"
    tempSheet.Cells(1, 2).Value = "Table Name"
    tempSheet.Cells(1, 3).Value = "Project"
    tempSheet.Cells(1, 4).Value = "Table Description"

    ' Center align headers
    tempSheet.Range("A1:D1").HorizontalAlignment = xlCenter

    ' Apply borders to headers
    With tempSheet.Range("A1:D1").Borders(xlEdgeBottom)
        .LineStyle = xlContinuous
        .Weight = xlThin
    End With

    ' Loop through the original data and copy it to the temporary sheet
    For i = 2 To lastRow
        tempSheet.Cells(i, 1).Value = ws.Cells(i, 1).Value ' Database
        tempSheet.Cells(i, 2).Value = ws.Cells(i, 2).Value ' Table Name
        tempSheet.Cells(i, 3).Value = ws.Cells(i, 3).Value ' Project
        tempSheet.Cells(i, 4).Value = ws.Cells(i, 4).Value ' Table Description
    Next i

    ' Set alignment for columns A, B, and C
    With tempSheet.Range("A2:A" & lastRow)
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlCenter
    End With
    With tempSheet.Range("B2:B" & lastRow)
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlCenter
    End With
    With tempSheet.Range("C2:C" & lastRow)
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlCenter
    End With

    ' Set alignment for column D
    With tempSheet.Range("D2:D" & lastRow)
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlTop
        .WrapText = True
    End With

    ' Set column width for the Table Description column
    tempSheet.Columns("D").ColumnWidth = 50

    ' Apply borders to all cells
    tempSheet.Range("A1:D" & lastRow).Borders(xlEdgeLeft).LineStyle = xlContinuous
    tempSheet.Range("A1:D" & lastRow).Borders(xlEdgeTop).LineStyle = xlContinuous
    tempSheet.Range("A1:D" & lastRow).Borders(xlEdgeBottom).LineStyle = xlContinuous
    tempSheet.Range("A1:D" & lastRow).Borders(xlEdgeRight).LineStyle = xlContinuous
    tempSheet.Range("A1:D" & lastRow).Borders(xlInsideVertical).LineStyle = xlContinuous
    tempSheet.Range("A1:D" & lastRow).Borders(xlInsideHorizontal).LineStyle = xlContinuous

    ' Autofit entire sheet
    tempSheet.Columns("A:D").AutoFit
    tempSheet.Rows.AutoFit

    ' Define the PDF path
    pdfPath = ThisWorkbook.Path & "\" & Left(ThisWorkbook.Name, Len(ThisWorkbook.Name) - 5) & ".pdf"

    ' Check if the file already exists and delete if it does
    If Dir(pdfPath) <> "" Then
        Kill pdfPath
    End If

    ' Set page orientation to landscape and add page numbers to the footer
    With tempSheet.PageSetup
        .Orientation = xlLandscape
        .CenterFooter = "Page &P of &N"
    End With

    ' Export the temporary sheet to PDF
    tempSheet.ExportAsFixedFormat Type:=xlTypePDF, Filename:=pdfPath, Quality:=xlQualityStandard, IncludeDocProperties:=True, IgnorePrintAreas:=False, OpenAfterPublish:=True

    ' Delete the temporary sheet
    Application.DisplayAlerts = False
    tempSheet.Delete
    Application.DisplayAlerts = True

    MsgBox "PDF has been created and saved to: " & pdfPath

End Sub
