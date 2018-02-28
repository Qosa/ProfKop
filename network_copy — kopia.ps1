﻿
function localDiskChecker($user,$path,$disks) {
# FUNKCJA USTALAJACA GDZIE NA DYSKU ZNAJDUJE SIE PROFIL UZYTKOWNIKA     
    for($x=0; $x -le 6; $x++) {
        $letter=$disks[$x]+':'
        $fin1="$letter$path$user"
        $break_counter = 0
	    if (Test-Path $fin1) {
		    Write-Host "UZYTKOWNIK ZALOGOWANY NA PARTYCJI --->>" $disks[$x]
		    $disks[$x]=0 
            $break_counter++
            return $fin1
            break } 
    }
    if ($break_counter -eq 0) {
            Write-Host "UZYTKOWNIK NIEZALOGOWANY!"
            userFirstLogon
     }
}

function checkNetworkDrive($ip_address,$disks, $user, $path){
# FUNKCJA USTALAJACA GDZIE NA DYSKU KOMPUTERA ZDALNEGO ZNAJDUJE SIE PROFIL UZYTKOWNIKA
    $ip_address_withslashes = '\\'+$ip_address+'\'
    if(Test-Connection $ip_address -ErrorAction Ignore){ #sprawdzenie, czy host odpowiada
         $complete_path = 0
         $break_counter = 0
         for($x=0; $x -le 6; $x++) {
            $letter=$disks[$x]+'$'
            $fin2="$ip_address_withslashes$letter$path$user"
	        if (Test-Path $fin2) {
                $break_counter++ 
                $complete_path = $fin2
                break
            }
           }
         }
     else { # problem z polaczeniem z hostem 
        $complete_path = -1 }
     return $complete_path
 }

function errorchecker($fin1){
# SPRAWDZENIE DOSTEPNOSCI HOSTA ORAZ CZY PROFIL ZNAJDUJE SIE NA PODANYM KOMPUTERZE
    if($fin1 -eq 0) {
        Write-Host "UZYTKOWNIK NIEZALOGOWANY! PRZED ROZPOCZECIEM KOPIOWANIA PROFILU ZALOGUJ UZYTKOWNIKA NA ZDALNYM KOMPUTERZE I URUCHOM SKRYPT PONOWNIE!"
        pause
	    exit
    }
    elseif($fin1 -eq -1){
        Write-Host "PROBLEM Z POLACZENIEM Z HOSTEM DOCELOWYM"
        pause
        exit
    }
}

function userFirstLogon{
# PIERWSZE LOGOWANIE UZYTKOWNIKA - TYLKO DYSKI LOKALNE
	try
	{
        $proc = Start-Process cmd.exe -WorkingDirectory 'C:\Windows\System32' -Credential "solaris_pl\" -PassThru
        Write-Host $proc.Id
        kill $proc.Id -Force
	}
	catch [System.Management.Automation.ParameterBindingException] 
	{
		Write-Host "Anulowano!"
	}
	catch [System.InvalidOperationException]
	{
		Write-Host "Zle haslo!"
	}
}

function ifLocal($ip_address){
# SPRAWDZA, CZY UZYTKOWNIK WYBRAL KOPIOWANIE Z LOKALNEGO DYSKU
    if($ip_address -eq 'L' -or $ip_address -eq 'l'){ 
        $fin1 = localDiskChecker $user $path $disks
        return $fin1
    }
    else {
        $fin1 = checkNetworkDrive $ip_address $disks $user $path
        errorchecker $fin1
        return $fin1
    }
}

function copyFiles($fin1, $fin2, $additionalFiles){
    # ----- ROZPOCZECIE KOPIOWANIA -----
    xcopy /c/e/h/y/i  $fin1\Desktop $fin2\Desktop
    xcopy /c/e/h/y/i  $fin1\Documents $fin2\Documents
    xcopy /c/e/h/y/i '$fin1\My Documents' '$fin2\My Documents'
    xcopy /c/e/h/y/i  $fin1\Pictures $fin2\Pictures
    xcopy /c/e/h/y/i  $fin1\Music $fin2\Music
    xcopy /c/e/h/y/i  $fin1\Favorites $fin2\Favorites
    xcopy /c/e/h/y/i  $fin1\Contacts $fin2\Contacts
    xcopy /c/e/h/y/i  $fin1\Videos $fin2\Videos
    xcopy /c/e/h/y/i  $fin1\Downloads $fin2\Downloads

    # ----- DANE APLIKACJI -----
    xcopy /c/e/h/y/i $fin1\AppData\Local\IBM\Notes\Data\names.nsf $fin2\AppData\Local\IBM\Notes\Data\
    xcopy /c/e/h/y/i $fin1\AppData\Local\IBM\Notes\Data\user.id $fin2\AppData\Local\IBM\Notes\Data\
    xcopy /c/e/h/y/i $fin1\AppData\Local\IBM\Notes\Data\desktop8.ndk $fin2\AppData\Local\IBM\Notes\Data\
    xcopy /c/e/h/y/i $fin1\AppData\Local\IBM\Notes\Data\archive $fin2\AppData\Local\IBM\Notes\Data\
    xcopy /c/e/h/y/i $fin1\AppData\Roaming\IBM\Sametime $fin2\AppData\Roaming\IBM\Sametime
    xcopy /c/e/h/y/i $fin1\AppData\Roaming\Mozilla $fin2\AppData\Roaming\Mozilla
    xcopy /c/e/h/y/i $fin1\My Documents\ $fin2\My Documents\
    xcopy /c/e/h/y/i $fin1\NTUSER.DAT $fin2

    foreach($item in $additionalFiles)
    {
        xcopy /c/e/h/y/i $item D:\DodatkowePliki
    }
}

Function getFileName {
# WYWOLYWANIE OKNA DO WYBORU DODATKOWYCH PLIKOW
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

# ----------------------------> MAIN <-------------------------------
if($False){ #$env:UserName[1] -ne "_"
    Write-Host "BLAD!URUCHOM SKRYPT JAKO ADMINISTRATOR DOMENOWY!"
    exit
} else {
    $disks = 'c','d','e','f','g','h','i'
    $user = Read-Host "PODAJ LOGIN UZYTKOWNIKA"
    $path = '\Users\'
    $returnFlag = 0
    # ----- WYBOR METODY KOPIOWANIA DANYCH -----
    Write-Host " ---------------------------------- "
    Write-Host " ------------- KOPIUJ ------------- "
    Write-Host " 1 > KOPIOWANIE Z DYSKU "
    Write-Host " 2 > KOPIOWANIE PRZEZ SIEC " 
    $option_choice = Read-Host "WYBIERZ OPCJE: "

    if ($option_choice -eq 1) { # KOPIOWANIE Z DYSKU USB NA DYSK LOKALNY
        $addFile = 0 
        $additionalFiles = [System.Collections.ArrayList]@()
        $fin1 = localDiskChecker $user $path $disks
        Write-Host $fin1
        $fin2 = localDiskChecker $user $path $disks 
        Write-Host $fin2
        while($addFile -eq 0){
            $addPrompt = Read-Host "CZY CHCESZ DODAC PLIK? (Y) Jezeli nie - nacisnij dowolny klawisz..."
            if($addPrompt -eq "Y" -or $addPrompt -eq "y") {
                $filename = getFileName
                $additionalFiles.Add($filename)
            } else {
                    Write-Host $additionalFiles
                    $addFile=1
            }
        }
        copyFiles $fin1 $fin2 $additionalFiles
        }

    elseif ($option_choice -eq 2){ # KOPIOWANIE PO SIECI
        while($returnFlag -eq 0){
        $ip_address = Read-Host "Z KOMPUTERA(ADRES IP - JEZELI LOKALNY WPISZ 'L'): "
        $fin1 = ifLocal $ip_address

        $ip_address2 = Read-Host "NA KOMPUTER(ADRES IP - JEZELI LOKALNY WPISZ 'L'): "
	#$ip_address[0] -ne '\' -and $ip_address2[0] -ne '\'
	$i=1
        if($i -ne 1){
            Write-Host "W OBU PRZYPADKACH WYBRANO KOPIOWANIE LOKALNE - OPERACJA NIEDOZWOLONA!"
            pause
            $returnFlag = 0
            Clear-Host
        }
        else {
            $fin2 = ifLocal $ip_address2

            Write-Host "DYSK1: " + $fin1 
            Write-Host "DYSK2: " + $fin2

            copyFiles $fin1 $fin2

            $returnFlag = 1
        }
    }
    }

    else {
        Write-Host "NIE MA TAKIEJ OPCJI! SPROBUJ PONOWNIE!"
    }
    Pause
    Stop-Transcript
}
