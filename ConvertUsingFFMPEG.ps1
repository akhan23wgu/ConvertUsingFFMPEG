####  Change values below to match your enviroment #####


### Specify Directories below ###

# TV Shows directory
$TvShowDir = "M:\TV"

# Movies directory
$MovieDir = "M:\Movies"

# ffmpeg Directory (Wherever you extracted ffmpeg to.  Example: C:\Downloads\ffmpeg
$ffmpegDir = "D:\Documents\ffmpeg\bin"


##### Changes Below here are optional #####



### Change file size if desired below ###

# Look for TV Shows larger than this value
$TvShowSize = 1GB

# Look for Movies larger than this value
$MovieSize = 2GB


### Change file format to desired format, defaults to .mkv"

#File format must be either mkv or mp4
$FileFormat = "mp4"


##### These can be changed but will default to the extracted folder and the 64bit install of ffmpeg #####

# Create Variable for storing the current directory
if (!$WorkingDir){
    $WorkingDir = (Resolve-Path .\).Path
}

# Spreadsheet containing completed conversions information. Do not change unless you want it to go to a differnt path
$ConversionCompleted = "$WorkingDir\ConversionsCompleted.csv"
if(Test-Path($ConversionCompleted)){
    $ConversionCompleted = Resolve-Path -Path $ConversionCompleted
}

# Directory you want log files to go to
$LogFileDir = "$WorkingDir\Logs"
if(Test-Path($LogFileDir)){
    $LogFileDir = Resolve-Path -Path $LogFileDir
}




##### DO NOT CHANGE BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING #####




### Check to make sure all paths and files exist before starting ###

# Create the Conversion Completed Spreadsheet if it does not exist
If(-not(Test-Path $ConversionCompleted)){
    $headers = "File Name", "Completed Date"
    $psObject = New-Object psobject
    foreach($header in $headers)
    {
     Add-Member -InputObject $psobject -MemberType noteproperty -Name $header -Value ""
    }
    $psObject | Export-Csv $ConversionCompleted -NoTypeInformation
    $ConversionCompleted = Resolve-Path -Path $ConversionCompleted
}

# Create the Logs directory if it does not exist
if(-not(Test-Path($LogFileDir))){
    New-Item -ItemType Directory -Force -Path $LogFileDir | Out-Null
    $LogFileDir = Resolve-Path -Path $LogFileDir
}

# Check to see if ffmpeg.exe exists in $ffmpegDir
if(-not(Test-Path("$ffmpegDir\ffmpeg.exe"))){
    Write-Host "ffmpeg.exe not found in $HandBreakDir Please make sure that HandBreak is installed.  Quitting" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# Check to see if $MovieDir exists
if(-not(Test-Path("$MovieDir"))){
    Write-Host "Movie directory: $MovieDir not found.  Please make sure the path is correct.  Quitting" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# Check to see if $TvShowDir exists
if(-not(Test-Path("$TvShowDir"))){
    Write-Host "Tv Show directory: $TvShowDir not found.  Please make sure the path is correct.  Quitting" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

#Create Hash table to check against before starting conversions.  This will prevent converting items that have already been converted (This spreadsheet updates automatically)
$CompletedTable = Import-Csv -Path $ConversionCompleted
$HashTable=@{}
foreach($file in $CompletedTable){
    $HashTable[$file."File Name"]=$file."Completed Date"
}


#####  Start looking for files and converting files happens after here #####

# Output that we are finding file
Write-Host "Finding Movie files over $($MovieSize/1GB)GB in $MovieDir and Episodes over $($TvShowSize/1GB)GB in $TvShowDir in the last 24 hours..." -ForegroundColor Gray

# Find all files larger than 2GB
$LargeTvFiles = Get-ChildItem $TVShowDir -recurse | where-object {(($_.length -gt $TVShowSize) -and ($_.CreationTime -gt (Get-Date).AddDays(-1)))} | Select-Object FullName,Directory,BaseName,Length
$LargeMovieFiles = Get-ChildItem $MovieDir -recurse | where-object {(($_.length -gt $MovieSize) -and ($_.CreationTime -gt (Get-Date).AddDays(-1)))} | Select-Object FullName,Directory,BaseName,Length

# Merge the files from both locations into one array and sort largest to smallest (So we start by converting the largest file first)
$AllLargeFiles = $LargeTvFiles
$AllLargeFiles += $LargeMovieFiles
$AllLargeFiles = $AllLargeFiles | Sort-Object length -Descending

# Run through a loop for each file in our array, converting it to a .$FileFormat file
foreach($File in $AllLargeFiles){
    # Full file name and path
    $InputFile = $File.FullName
    # File name + "-NEW.$FileFormat" we want it to be an $FileFormat file and we don't want to overwrite the file we are reading from if it is already a .$FileFormat
    $OutputFile = "$($File.Directory)\$($File.BaseName)-NEW.$FileFormat"
    # Just the file itself
    $EpisodeName = $File.BaseName
    #Fix brakets in the logfile name.
    $LogEpisodeName = $EpisodeName -replace '[[\]]',''
    # The final name that we will rename it to when the conversion is finished and we have deleted the original
    $FinalName = "$($File.Directory)\$($File.BaseName).$FileFormat"
    # Check the Hash table we created from the Conversions Completed spreadsheet.  If it exists skip that file
    if(-not($HashTable.ContainsKey("$FinalName"))){
		# Check that the Output file does not already exist, if it does delete it so the new conversions works as intended.
        if(Test-Path $OutputFile){
            Remove-Item $OutputFile -Force
        }
        # Change the CPU priorety of HandBreakCLI.exe to below Normal in 10 seconds so that the conversion has started
        Start-Job -ScriptBlock {
            Start-Sleep -s 10
            $p = Get-Process -Name ffmpeg
            $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
        } 
        # Write that we are starting the conversion
        $StartingFileSize = $File.Length/1GB
        Write-Host "Starting conversion on $InputFile it is $([math]::Round($StartingFileSize,2))GB in size before conversion" -ForegroundColor Cyan
        # I messed with the settings until I found it acceptable. Obviously quality won't be as good as source, but the file size is much much smaller. (example: 2.6GB file went down to 600MB.)
		#https://www.reddit.com/r/PleX/comments/56v7s1/hevc_encoding_1080p_using_nvenc_for_devices_that/
		###NVENC_HighQuality_HelpsWithMotion_PlusColorConversion### *Requires 10xx GPU
		#& $ffmpegDir\ffmpeg.exe -i "$InputFile" -c:v hevc_nvenc -pix_fmt yuv444p16 -profile:v main10 -preset slow -rc vbr_2pass -qmin 15 -qmax 20 -2pass 1 -rc-lookahead 32 -c:a:0 copy "$OutputFile" 2> "$LogFileDir\$LogEpisodeName.txt"
		###NVENC_HighQuality_Standard### *Requires nVidia 10xx GPU - I used a 1050Ti, average 190fps
		& $ffmpegDir\ffmpeg.exe -i "$InputFile" -c:v nvenc_hevc -b:v 2000k -minrate 800k -profile:v main10 -preset llhq -rc vbr_2pass -qmin 25 -qmax 35 -rc-lookahead 32 -c:a:0  copy "$OutputFile" 2> "$LogFileDir\$LogEpisodeName.txt"


        # Check to make sure that the output file actually exists so that if there was a conversion error we don't delete the original
        if( Test-Path $OutputFile ){
            Remove-Item $InputFile -Force
            Rename-Item $OutputFile $FinalName
            Write-Host "Finished converting $FinalName" -ForegroundColor Green
            $EndingFile = Get-Item $FinalName | Select-Object Length
            $EndingFileSize = $EndingFile.Length/1GB
            Write-Host "Ending file size is $([math]::Round($EndingFileSize,2))GB so, space saved is $([math]::Round($StartingFileSize-$EndingFileSize,2))GB" -ForegroundColor Green
            # Add the completed file to the completed csv file so we don't convert it again later
            $csvFileName = "$FinalName"
            $csvCompletedDate = Get-Date -UFormat "%x - %I:%M %p"
            $hash = @{
                "File Name" =  $csvFileName
                "Completed Date" = $csvCompletedDate
            }
            $newRow = New-Object PsObject -Property $hash
            Export-Csv $ConversionCompleted -inputobject $newrow -append -Force
        }
        # If file not found write that the conversion failed.
        elseif (-not(Test-Path $OutputFile)){
            Write-Host "Failed to convert $InputFile" -ForegroundColor Red
        }
    }
    # If file exists in Conversions Completed Spreadsheet write that we are skipping the file because it was already converted
    elseif($HashTable.ContainsKey("$FinalName")){
        $CompletedTime = $HashTable.Item("$Finalname")
        Write-Host "Skipping $InputFile because it was already converted on $CompletedTime." -ForegroundColor DarkGreen
    }
    # Cleanup our variables so there is nothing leftover for the next run
    Clear-Variable InputFile,OutputFile,EpisodeName,FinalName,AllLargeFiles,TvShowDir,MovieDir,LargeMovieFiles,LargeTvFiles,File,EndingFile,EndingFileSize,TvShowSize,MovieSize -ErrorAction SilentlyContinue

}
