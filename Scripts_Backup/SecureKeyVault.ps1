<#
.SYNOPSIS
    Secure Vault Viewer
    Entschlüsselt den eingebetteten Inhalt nur mit dem korrekten Passwort.
    
    Passwort für diesen Container: Lara04092019!
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- ENCRYPTED BLOB (DO NOT EDIT) ---
$EncryptedBlob = "L4Jmmpnw+oik10onUTK5xHAGedXAR3ryACydXS4iVQAj87sj6CdbN9EBRpg163RRgmQF201u90QIUaaXPz8IuAGPpOv7gZesyeqQ5eC+yZkj9OOLe5WAB7TZ2YdRyj5/yRNotzRFqHcrb+BWngiv8b795zWUluzWeZIOkDQzWjV15VPUPOfQUA41sQtzecpZeRg9sieowVitwpno51tduoEVYIZ6TQ46DpQc2uU8a2/PaiMW3XgvPOVIAFS3yJ9CsmIIIXIVW4GtGRv8UIV4ln+go6VF/vlhhJYxKcqjd3piobymwSmuevytTpBuJivKfbsJ2n1AMIN1QdNA8jBEKrZoH10LMluQ/l3yImT5ETX+MLbVRoQ5ZswxyD8KqsCrEpf7BD0xnU4CDTjMFNfi0g=="

# --- GUI SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sicherheits-Tresor"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "Bitte Passwort eingeben:"
$lbl.Location = New-Object System.Drawing.Point(20, 20)
$lbl.AutoSize = $true
$form.Controls.Add($lbl)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(20, 50)
$txtPass.Size = New-Object System.Drawing.Size(340, 25)
$txtPass.PasswordChar = "*"
$form.Controls.Add($txtPass)

$btnDecrypt = New-Object System.Windows.Forms.Button
$btnDecrypt.Text = "Entsperren"
$btnDecrypt.Location = New-Object System.Drawing.Point(20, 90)
$btnDecrypt.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnDecrypt)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Beenden"
$btnExit.Location = New-Object System.Drawing.Point(130, 90)
$btnExit.Size = New-Object System.Drawing.Size(100, 30)
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

# --- DECRYPTION LOGIC ---
$btnDecrypt.Add_Click({
    try {
        $password = $txtPass.Text
        
        # 1. Derive Key
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $keyBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($password))
        
        # 2. Prepare Cipher
        $cipherBytes = [Convert]::FromBase64String($EncryptedBlob)
        
        # 3. Extract IV (First 16 bytes)
        $iv = $cipherBytes[0..15]
        $actualCipher = $cipherBytes[16..($cipherBytes.Length-1)]
        
        # 4. Decrypt
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $keyBytes
        $aes.IV = $iv
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        
        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($actualCipher, 0, $actualCipher.Length)
        $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
        
        # 5. Show Success
        $form.Hide()
        [System.Windows.Forms.MessageBox]::Show("Zugriff gewährt!", "Erfolg", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
        # Create Result Window
        $resultForm = New-Object System.Windows.Forms.Form
        $resultForm.Text = "Tresor Inhalt"
        $resultForm.Size = New-Object System.Drawing.Size(500, 400)
        $resultForm.StartPosition = "CenterScreen"
        
        $txtResult = New-Object System.Windows.Forms.TextBox
        $txtResult.Multiline = $true
        $txtResult.ScrollBars = "Vertical"
        $txtResult.ReadOnly = $true
        $txtResult.Dock = "Fill"
        $txtResult.Font = New-Object System.Drawing.Font("Consolas", 10)
        $txtResult.Text = $decryptedText
        
        $resultForm.Controls.Add($txtResult)
        $resultForm.ShowDialog()
        $form.Close()
        
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Falsches Passwort oder beschädigte Daten.", "Zugriff verweigert", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        $txtPass.Text = ""
    }
})

$form.ShowDialog()
