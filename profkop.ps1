
function userFirstLogon{
# PIERWSZE LOGOWANIE UZYTKOWNIKA - TYLKO DYSKI LOKALNE    
    $first_logon_flag = 0
    while($first_logon_flag -eq 0){
        Try {
            $proc = Start-Process cmd.exe -WorkingDirectory 'C:\Windows\System32' -Credential "solaris_pl\" -PassThru
            Write-Host $proc.Id
            kill $proc.Id -Force
            return 1
        } Catch {
            $try_again = Read-Host "PODALES NIEPRAWIDLOWA NAZWE UZYTKOWNIKA LUB HASLO!!! SPROBOWAC PONOWNIE? (Y - tak, N - od poczatku, dowolny klawisz + enter - wyjscie)"
            if($try_again -eq 'Y' -or $try_again -eq 'y'){
                #NASTEPNY CYKL PETLI
            } elseif($try_again -eq 'N' -or $try_again -eq 'n') {
                return 0
            } else {
                Clear-Host
                exit
            }
        }
    }
}

function localDiskChecker($user,$path,$disks,$local_flag) {
# FUNKCJA USTALAJACA GDZIE NA DYSKU ZNAJDUJE SIE PROFIL UZYTKOWNIKA     
    for($x=0; $x -le 6; $x++) {
        $letter=""+$disks[$x]+':'
        $fin1="$letter$path$user"
        $break_counter = 0
	    if (Test-Path $fin1) {
		    Write-Host "UZYTKOWNIK ZALOGOWANY NA PARTYCJI --->>" $disks[$x]
		    $disks[$x]=0 
            $break_counter++
            return $fin1
            break } 
    }
    if($local_flag -eq 0){    
        if ($break_counter -eq 0) {
                $not_logged_in = Read-Host "UZYTKOWNIK NIEZALOGOWANY NA TYM KOMPUTERZE! CZY CHCESZ GO ZALOGOWAC? (Y - tak, N - od poczatku, dowolny klawisz + enter - wyjscie)"
                if($not_logged_in -eq 'Y' -or $not_logged_in -eq 'y'){
                    return userFirstLogon
                } elseif ($not_logged_in -eq 'N' -or $not_logged_in -eq 'n') {
                    return 0
                }
                else {
                    Clear-Host
                    exit
                }
        }
    }
    elseif($local_flag -eq 1){
        $try_again = Read-Host "UZYTKOWNIK NIEZALOGOWANY NA DYSKU ZEWNETRZNYM! SPROBOWAC PONOWNIE? (Y - tak, dowolny klawisz + enter - wyjscie)"
        if($try_again -eq 'Y' -or $try_again -eq 'y'){
            return 0
        } else {
            Clear-Host
            exit
        }

    }        
}

function checkNetworkDrive($ip_address,$disks, $user, $path){
# FUNKCJA USTALAJACA GDZIE NA DYSKU KOMPUTERA ZDALNEGO ZNAJDUJE SIE PROFIL UZYTKOWNIKA
    $ip_address_withslashes = '\\'+$ip_address+'\'
    if(Test-Connection $ip_address -ErrorAction Ignore){ #sprawdzenie, czy host odpowiada
         $complete_path = 0
         $break_counter = 0
         for($x=0; $x -le 6; $x++) {
            $letter=""+$disks[$x]+'$'
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
        $try_again = Read-Host "PROBLEM Z POLACZENIEM Z HOSTEM DOCELOWYM BADZ PODANO NIEPRAWIDLOWA NAZWE/ADRES HOSTA! SPROBOWAC PONOWNIE? (Y - tak, dowolny klawisz + enter - wyjscie)"
        if($try_again -eq 'Y' -or $try_again -eq 'y'){
            return 0
        } else {
            Clear-Host
            exit
        }
    }
}

function ifLocal($ip_address, $user){
# SPRAWDZA, CZY UZYTKOWNIK WYBRAL KOPIOWANIE Z LOKALNEGO DYSKU
    if($ip_address -eq 'L' -or $ip_address -eq 'l'){ 
        $local_flag = 0
        $fin1 = localDiskChecker $user $path $disks $local_flag
        Write-Host $fin1
        return $fin1
    }
    else {
        $fin1 = checkNetworkDrive $ip_address $disks $user $path
        errorchecker $fin1
        return $fin1
    }
}

function summary($fin1,$fin2,$additionalfiles) {
   Clear-Host
   Write-Host "`n-----> PODSUMOWANIE:" 
   $items =  Get-ChildItem $fin1'\Documents',$fin1'\Desktop',$fin1'\My Documents',$fin1'\Pictures',$fin1'\Music',$fin1'\Favorites',$fin1'\Contacts',$fin1'\Videos',$fin1'\Downloads' -Recurse
   $total_amount_of_elems = ($items | Measure-Object).Count 
   $total_size_of_elems = [math]::Round(($items | Measure-Object -Sum Length).Sum / 1GB,3)
   Write-Host "-----------> Z: "$fin1[0]" NA: "$fin2[0]
   Write-Host "-----------> DO SKOPIOWANIA OGOLEM:"$total_amount_of_elems" elementow"
   Write-Host "-----------> DODATKOWE PLIKI:"
   for($x=0; $x -le ($additionalfiles | Measure-Object).Count; $x++) {  
       Write-Host "      "$additionalfiles[$x]
   }
   Write-Host "-----------> CALKOWITY ROZMIAR:"$total_size_of_elems" GB"
}

function copyFiles($fin1, $fin2, $additionalfiles){
    $FOF_CREATEPROGRESSDLG = "&H0&"
    
    $objShell = New-Object -ComObject "Shell.Application"

    $objFolder = $objShell.NameSpace($fin2+'\Documents')
    $objFolder.CopyHere($fin1+'\Documents', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Desktop') 
    $objFolder.CopyHere($fin1+'\Desktop', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\My Documents') 
    $objFolder.CopyHere($fin1+'\My Documents', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Pictures') 
    $objFolder.CopyHere($fin1+'\Pictures', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Music') 
    $objFolder.CopyHere($fin1+'\Music', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Favorites') 
    $objFolder.CopyHere($fin1+'\Favorites', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Contacts')  
    $objFolder.CopyHere($fin1+'\Contacts', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Videos') 
    $objFolder.CopyHere($fin1+'\Videos', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Downloads')  
    $objFolder.CopyHere($fin1+'\Downloads', $FOF_CREATEPROGRESSDLG)

    $objFolder = $objShell.NameSpace($fin2+'\AppData\Local\IBM\Notes\Data\') 
    $objFolder.CopyHere($fin1+'\AppData\Local\IBM\Notes\Data\names.nsf', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\AppData\Local\IBM\Notes\Data\') 
    $objFolder.CopyHere($fin1+'\AppData\Local\IBM\Notes\Data\user.id', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\AppData\Local\IBM\Notes\Data\') 
    $objFolder.CopyHere($fin1+'\AppData\Local\IBM\Notes\Data\desktop8.ndk', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\AppData\Local\IBM\Notes\Data\') 
    $objFolder.CopyHere($fin1+'\AppData\Local\IBM\Notes\Data\archive', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\AppData\Roaming\IBM\Sametime') 
    $objFolder.CopyHere($fin1+'\AppData\Roaming\IBM\Sametime', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\AppData\Roaming\Mozilla') 
    $objFolder.CopyHere($fin1+'\AppData\Roaming\Mozilla', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2+'\Documents') 
    $objFolder.CopyHere($fin1+'\Documents', $FOF_CREATEPROGRESSDLG)
    $objFolder = $objShell.NameSpace($fin2) 
    $objFolder.CopyHere($fin1+'\NTUSER.DAT', $FOF_CREATEPROGRESSDLG)

    foreach($item in $additionalFiles)
    {
        $objFolder = $objShell.NameSpace($fin2[0]+':\DodatkowePliki') 
        $objFolder.CopyHere($item, $FOF_CREATEPROGRESSDLG)
    }

    <#
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
    #>
}

Function getFileName {
# WYWOLYWANIE OKNA DO WYBORU DODATKOWYCH PLIKOW
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

Function addFiles {
    $addFile = 0 
        $additionalFiles = [System.Collections.ArrayList]@()
        while($addFile -eq 0){
            $addPrompt = Read-Host "CZY CHCESZ DODAC PLIK? (Y - tak, nie - nacisnij dowolny klawisz...)"
            if($addPrompt -eq "Y" -or $addPrompt -eq "y") {
                $filename = getFileName
                [void]$additionalFiles.Add($filename)
            } else {
                    $addFile=1
                    return $additionalFiles
            }
        }
}




# ----------------------------> MAIN <-------------------------------
if($False){ #$env:UserName[1] -ne "_"
    Write-Host "BLAD!URUCHOM SKRYPT JAKO ADMINISTRATOR DOMENOWY!"
    exit
} else {
    $disks = 'c','d','e','f','g','h','i'
    $path = '\Users\'
    $local_flag = 0
    $returnFlag = 0

    # ----- WYBOR METODY KOPIOWANIA DANYCH -----
    Write-Host " ---------------------------------- "
    Write-Host " ------------- KOPIUJ ------------- "
    Write-Host " 1 > KOPIOWANIE Z DYSKU "
    Write-Host " 2 > KOPIOWANIE PRZEZ SIEC " 
    $option_choice = Read-Host "WYBIERZ OPCJE: "

    # ----- KOPIOWANIE Z DYSKU USB NA DYSK LOKALNY
    if ($option_choice -eq 1) { 
        $disk_flag = 0
        $disk_flag2 = 0
        while($disk_flag -eq 0){
            while($disk_flag2 -eq 0){
            Clear-Host
            Write-Host "-------------> KOPIOWANIE Z DYSKU <-------------`n" 
            $user = Read-Host "PODAJ LOGIN UZYTKOWNIKA"
            $fin2 = localDiskChecker $user $path $disks $local_flag #DESTINATION
            Write-Host ">LOKALIZACJA: "$fin2
            if($fin2 -ne 0){
                $disk_flag2 = 1
            }
        }
            $local_flag = 1
            $fin1 = localDiskChecker $user $path $disks $local_flag #SOURCE
            Write-Host ">LOKALIZACJA: "$fin1
            if($fin1 -ne 0){
                $disk_flag = 1
            } elseif($fin1 -eq 0) {
                $disk_flag2 = 0
                $local_flag = 0
            }            
        }
        $additionalfiles = addFiles
        summary $fin1 $fin2 $additionalfiles
        pause
        copyFiles $fin1 $fin2 $additionalFiles
        }
        
    # ----- KOPIOWANIE PO SIECI 
    elseif ($option_choice -eq 2){ 
        while($returnFlag -eq 0){
        Clear-Host
        Write-Host "-------------> KOPIOWANIE PRZEZ SIEC <-------------`n"     
        $user = Read-Host "PODAJ NAZWE UZYTKOWNIKA: "
        $ip_address = Read-Host "Z KOMPUTERA(ADRES IP - JEZELI LOKALNY WPISZ 'L'): "
        $ip_address2 = Read-Host "NA KOMPUTER(ADRES IP - JEZELI LOKALNY WPISZ 'L'): "
        if(($ip_address -eq 'l' -or $ip_address -eq 'L') -and ($ip_address2 -eq 'l' -or $ip_address2 -eq 'L')) {
            Write-Host "W OBU PRZYPADKACH WYBRANO KOPIOWANIE LOKALNE - OPERACJA NIEDOZWOLONA!"
            pause
            $returnFlag = 0
            Clear-Host
        }
        else {
            $fin1 = ifLocal $ip_address $user
            $fin2 = ifLocal $ip_address2 $user
            if($fin1 -eq 0 -or $fin2 -eq 0) {
                $returnFlag = 0
            } else {
                Write-Host "DYSK1(Z): " $fin1 
                Write-Host "DYSK2(NA): " $fin2
                $additionalfiles = addFiles
                summary $fin1 $fin2 $additionalfiles
                pause
                copyFiles $fin1 $fin2 $additionalfiles
            }
        }
    }
    }

    else {
        Write-Host "NIE MA TAKIEJ OPCJI! SPROBUJ PONOWNIE!"
    }
    Pause
    Stop-Transcript
}
