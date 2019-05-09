# SampleQualityMonitor
Autonomously monitor user sample quality for flow cytometers

## This is alpha quality.  It is still under active development and should not be considered finished.

The idea here is to test user sample quality by checking time vs fluorescence, as we do during analysis, but at the time of acquisition.  This allows the core facility to be proactive helping our users spot problematic experiments and allows us to check for machine issues, such as recurrent blockages. 

Here I list all the newest fcs files (since that last check) and run them through the R package flowCut which looks for deviations in fluorescence over time.  The script then plots and records the “bad” files and emails the output to you.  The script also records other metrics of instrument usage and saves it as a csv file. 

Currently it only works in DIVA (as we have 3 BD machines), but when it is working well I will apply it to the CytoFlex too.  

## Instructions
*Install R
*Install the required R packages using:
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
*Create some folders as shown here:
*Put the scripts (R and PowerShell) into BDQC.
*Create a free gmail account and change the security settings to ‘less secure’ to allow scripted emails to be sent.
*Open the PowerShell script and change the “Username” and “Password” to those of the Gmail account.  Change the “From” to your Gmail email and the “To” to wherever you want to send it.
*Go to  windows Task Scheduler and add a taskt o run each morning that runs the program “Powershell.exe” with arguments:
> -ExecutionPolicy ByPass -File D:\BDQC\powershell.ps1
*Test the script by running it now.  If it does not work go into R and run the R script line by line to see where it is failing.  If it passes do the same with the PowerShell script.