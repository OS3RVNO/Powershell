$alfrescoUrl = "https://alfresco-site.com"
$username = "username"
$password = "password"

# Crea un header di autenticazione Basic
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:$password")))
$headers = @{ Authorization = "Basic $encodedCredentials" }

# Funzione per scaricare i file dalla cartella specificata
function Download-FilesFromNode {
    param (
        [string]$nodeId,
        [string]$currentPath
    )

    $url = "$alfrescoUrl/api/-default-/public/alfresco/versions/1/nodes/$nodeId/children"

    try {
        # Esegui la richiesta GET per ottenere i children
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

        # Controlla se ci sono file o cartelle
        if ($response.list.entries.Count -gt 0) {
            foreach ($entry in $response.list.entries) {
                $fileNodeId = $entry.entry.id
                $fileName = $entry.entry.name
                
                # Stampa informazioni sul file
                Write-Host "Scansione di: $fileName (ID: $fileNodeId)"
                
                if ($entry.entry.isFolder -eq $false) {
                    # Costruisci il percorso di salvataggio del file
                    $filePath = Join-Path -Path $currentPath -ChildPath $fileName

                    # Crea la cartella di destinazione se non esiste
                    $fileDirectory = Split-Path -Path $filePath -Parent
                    if (-not (Test-Path -Path $fileDirectory)) {
                        New-Item -ItemType Directory -Path $fileDirectory -Force | Out-Null
                        Write-Host "Creata cartella: $fileDirectory"
                    }

                    # Costruisci l'URL per scaricare il file
                    $downloadUrl = "$alfrescoUrl/api/-default-/public/alfresco/versions/1/nodes/$fileNodeId/content"
                    try {
                        # Scarica il file
                        Invoke-RestMethod -Uri $downloadUrl -Method Get -Headers $headers -OutFile $filePath
                        Write-Host "File scaricato: $filePath"
                    } catch {
                        Write-Host "Errore durante il download di ${fileName}: $($_.Exception.Message)"
                    }
                } else {
                    # Se è una cartella, chiamare ricorsivamente la funzione
                    $newPath = Join-Path -Path $currentPath -ChildPath $fileName
                    Download-FilesFromNode -nodeId $fileNodeId -currentPath $newPath
                }
            }
        } else {
            Write-Host "Nessun file o cartella trovato."
        }
    } catch {
        Write-Host "Errore durante la richiesta: $($_.Exception.Message)"
    }
}

# Funzione per comprimere la cartella in un file ZIP
function Compress-Folder {
    param (
        [string]$sourceFolder,
        [string]$zipFilePath
    )
    
    if (Test-Path -Path $sourceFolder) {
        # Assicurati di caricare il modulo necessario
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        # Comprimi la cartella
        [System.IO.Compression.ZipFile]::CreateFromDirectory($sourceFolder, $zipFilePath)
        Write-Host "Cartella compressa in: $zipFilePath"
    } else {
        Write-Host "La cartella non esiste: $sourceFolder"
    }
}

# Inizio il download dalla cartella principale
$rootNodeId = "2b4e5461-df0d-4b25-863b-37e1110d1ab7"  # NodeId della cartella principale
$rootPath = "\download\path"  # Modifica il percorso di destinazione
Download-FilesFromNode -nodeId $rootNodeId -currentPath $rootPath

# Comprime la cartella di download
$zipFilePath = "\download\path"  # Modifica il percorso e il nome del file ZIP
Compress-Folder -sourceFolder $rootPath -zipFilePath $zipFilePath