Imports System.IO
Imports System.Text
Imports System.Environment
Imports System

Public Class Form1

    Dim adminuser As String
    Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Dim timer As New Timer()
        Dim userid As String = Environment.UserName

        'I am using this to manipulate existing username
        'adminuser = userid.Substring(0, 2) & "adminuser"

        adminuser = userid

        timer.Interval = 1000
        UserName.Text = userid



        domainid.Text = adminuser
        AddHandler timer.Tick, AddressOf timer_Tick
        timer.Start()
    End Sub

    Private Sub timer_Tick(ByVal sender As Object, ByVal e As EventArgs)
        If TimerBox.Text = 0 Then
            RefreshButton.PerformClick()
            TimerBox.Text = 11
            'This is the location for locked out files, to show you if you account is locked out
            'change the server address
            Dim stpath As String = "\\FQDN-ServerName\sessionlogs\" & adminuser & ".locked"
            If File.Exists(stpath) Then
                accstat.Text = "Locked"
                accstat.BackColor = Color.Red
            Else
                accstat.Text = "Unlocked"
                accstat.BackColor = Color.Green
            End If
        End If
        TimerBox.Text = TimerBox.Text - 1
    End Sub

    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles RefreshButton.Click
        DataGridView1.Rows.Clear()
        'Location for csv file which gets imported to the form grid view
        'change the server address
        Dim fname As String = "\\FQDN-ServerName\sessionlogs\" & adminuser & ".csv"
        Dim noghost As String = "You are all good! No ghost sessions found!"
        filepath.Text = fname

        If FileIO.FileSystem.FileExists(Trim(fname)) Then
            If (New FileInfo(fname).Length = 0) Then
                DataGridView1.Rows.Add("")
                DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.BackColor = Color.DarkGreen
                DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.ForeColor = Color.White
                DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Value = noghost

            Else
                Dim colsexpected As Integer = 6
                Dim thereader As New StreamReader(fname, Encoding.Default)
                Dim sline As String = ""
                Do
                    sline = thereader.ReadLine

                    Dim i As Integer

                    If sline Is Nothing Then
                        i = i + 1
                        If i = 0 Then
                            DataGridView1.Rows.Add("")
                            DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.BackColor = Color.DarkGreen
                            DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.ForeColor = Color.White
                            DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Value = noghost
                        End If
                        Exit Do

                    Else

                        Dim words() As String = sline.Split(",")
                        DataGridView1.Rows.Add("")

                        If words.Length = colsexpected Then
                            For ix As Integer = 0 To 5
                                DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(ix).Value = words(ix)

                            Next
                        Else


                            If words.Length = 1 Then
                                For ix As Integer = 0 To 0
                                    DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.BackColor = Color.DarkGreen
                                    DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.ForeColor = Color.White
                                    DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Value = noghost

                                Next
                            Else
                                DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.BackColor = Color.DarkRed
                                DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.ForeColor = Color.White
                                DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Value = "Error: Expected number of colums is 5, please check the CSV file!"

                            End If
                        End If
                    End If

                Loop
                thereader.Close()
            End If
        Else
            DataGridView1.Rows.Add("")
            DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.BackColor = Color.DarkGreen
            DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Style.ForeColor = Color.White
            DataGridView1.Rows(DataGridView1.Rows.Count - 1).Cells(0).Value = "The Filepath does not exist yet!"
        End If
    End Sub


    Private Sub Button1_Click_1(sender As Object, e As EventArgs) Handles Logout.Click
        'This is location of loggoff file, when you click Force Logoff button the file gets created
        'Change the servername and path
        Dim path As String = "\\FQDN-ServerName\sessionlogs\" & adminuser & ".logoff"
        If Not File.Exists(path) Then
            Using sw As StreamWriter = File.CreateText(path)
                sw.WriteLine("logoff all sessions")
            End Using
        End If
        MsgBox("All sessions will be logged off in a minute.", MsgBoxStyle.Information)
    End Sub

    Private Sub TextBox1_TextChanged(sender As Object, e As EventArgs) Handles accstat.TextChanged

    End Sub
End Class
