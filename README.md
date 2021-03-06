# ConvertUsingFFMPEG with NVENC Encoding
Powershell Script to automate conversion of video files a specified size or larger to smaller mkv or mp4 files. I have modified the original script to use NVENC encoding and only modify the files that were created in the last 24 hours.

# Pre Reqs
1. Must have ffmpeg installed.  You can get it here: <https://www.ffmpeg.org/>
2. Must have powershell setup to allow this script.  See [Powershell Setup](https://github.com/Rocketcandy/ConvertUsingHandBreakCLI#powershell-setup)
3. Powershell is a requirement to run the script.  I have only tested it on Windows, but if you can get it to work on MacOS or Linux more power to you!
4. Edit the script and change the first section of the script to match your needs

A couple notes about editing the script

1. All paths can be either a network path.  Example: "\\\\my.server\share\files"
2. Or a local path.  Example: "C:\Users\Public\Videos"
3. Just make sure that whatever path you use it stays inside the quotes.
 
# What does the script actually do?

1. By default it will look for all files in defined $MovieDir over 2GB and all files in defined $TvShowdir over 1GB (it will look for all files recursivly inside of the defined $MovieDir or $TvShowdir so just specify the base directory that includes all files you want to convert.)
2. Once it has found them all it will start converting them from largest to smallest
3. It will create a brand new file named: OriginalFileName-New
4. Once the conversion is completed it will delete the OriginalFileName and rename the newly converted file to match the OriginalFileName
5. When a conversion is completed it will add the file name and path to the csv spreadsheet and not try to convert it again.
6. If a conversion fails it does not delete the original file
7. If you do have a failed conversion you might have to delete the OriginalFileName-New file that was created before it failed.
8. You should only have to delete the OriginalFileName-New file if you kill powershell to stop converting.

# Running the script
1. After you have modified the variables and changed the execution policy right click on the script
2. Select Run with Powershell
3. You should see a Powershell window apear and you should see this apear at the top of the window:

    Finding Movie Files over xGB in \\\\Path\To\Movies and Episodes ove xGB in \\\\Path\To\Shows be patient...

4. If you see that message the script is running and conversions should start

# Powershell Setup
The easiest way to do this is to allow this script to run by using this command in powershell running as admin:

    Set-ExecutionPolicy Unrestricted

Select Yes to all when prompted

for more information on Execution Policy view this page: <https://technet.microsoft.com/library/hh847748.aspx>

# Other Information

1. Average to convert a 5GB file is 20 minutes
2. On average a 2GB file will take 10 minutes on a 1050Ti (Might be faster or slower depending on how new the GPU is)
3. NVENC encoding ONLY works on 9xx+ GPUs

# License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
