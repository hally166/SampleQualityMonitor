# SampleQualityMonitor
Autonomously monitor user sample quality for flow cytometers

### This is alpha quality.  It is still under active development and should not be considered finished.

Please pay attention to the licenses of the imported packages. Specifically flowCut is for academic use only.

The idea here is to test user sample quality by checking time vs fluorescence, as we do during analysis, but at the time of acquisition.  This allows the core facility to be proactive helping our users spot problematic experiments and allows us to check for machine issues, such as recurrent blockages. 

I list all the newest fcs files (since that last check) and run them through the R package flowCut (https://github.com/jmeskas/flowCut) which looks for deviations in fluorescence over time.  The script then plots and records the “bad” files and emails the output to you.  The script also records other metrics of instrument usage and saves it as a csv file. 

Currently it only works in DIVA (as we have 3 BD machines), but when it is working well I will apply it to the CytoFlex too.  
The output currently looks like this.

![example image](/example.png)

The big question is; how do you report this to the user?  We are still working on that.

## Instructions
On the flow cytometer PC.
* Install R
* Install the required R packages using:
```R
install.packages("BiocManager")
install.packages("devtools")
install.packages("xtable")
BiocManager::install("flowCore")
BiocManager::install("flowDensity")
devtools::install_github("jmeskas/flowCut")
#if the above flowCut install does not work then use the one below
devtools::install_github("hally166/flowCut")
```
* For BD machines create folders as shown here: D:/BDQC, D:/BDQC/Archive, D:/BDQC/Images, D:/BDQC/Summaries
* For Cytoflex machines create /QC/Images, /QC/Summaries, /QC/Archive
* Put the scripts (R and PowerShell) into BDQC or QC folder.
* Create a free gmail account and change the security settings to ‘less secure’ to allow scripted emails to be sent.
* Open the PowerShell script and change the “Username” and “Password” to those of the Gmail account.  Change the “From” to your Gmail email, the “To” to wherever you want to send it, and the "Subject" to anything you want.  Check that the location of the Rscript.exe is correct.
* Go to Windows Task Scheduler and add a task to run each morning that runs the program “Powershell.exe” with this argument:
> -ExecutionPolicy ByPass -File D:\BDQC\powershell.ps1
or something similar to this for the Cytolfex
> -ExecutionPolicy ByPass -File C:\Users\Operator\Documents\QC\powershell.ps1
* Test the script by running it now.  If it does not work go into R and run the R script line by line to see where it is failing.  If it passes do the same with the PowerShell script.  The biggest issue I have found so far is memory management.  DIVA is only 32bit, restricting the PC to 4GB of RAM, which is not ideal.  I have done a few things to reduce the memory footprint of the script, but as a fall back it will skip any files too large to be loaded into memory.  A future version will count these, but not this version.  It's best to get the script to run first thing, before starting to properly use the PC.
