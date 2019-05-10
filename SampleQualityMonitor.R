#Sample Quality Monitor script for checking user data quality autonomously
#Christopher Hall, Wellcome Sanger Institute Cytometry Core Facility, ch15@sanger.ac.uk
#GPL-3.0

#load packages
library(flowCore)
library(flowCut)
library(flowDensity)
library(xtable)

#list all the files in the BD DIVA database
files <- list.files(path="D:/BDDatabase/BDData/", pattern=".fcs$", full.names = TRUE)

#specify the locations of the export folders
imageLocation<-"D:/BDQC/Images/"
csvOUT<- "D:/BDQC/Summaries/"

#how far to go back in the database
if (file.exists(paste(csvOUT,"Summary",".csv", sep=""))) {
  LatestDate<-as.Date(tail(read.csv(paste(csvOUT,"Summary",".csv", sep=""))$DateTested, n=1), "%a %d %b %Y")
} else { LatestDate<- Sys.Date()-1
}

#function that runs flowCut and outputs the data
QCfunction<- function(filename){
  fcsfile <- try(read.FCS(filename))
  if (class(fcsfile) == 'flowFrame'){
    if (as.Date(keyword(fcsfile)["$DATE"][[1]], format = "%d-%b-%Y")>=LatestDate & !grepl("Cleaning",(keyword(fcsfile)["EXPERIMENT NAME"][[1]]), fixed=TRUE)){
      res_flowCut <- try(flowCut(fcsfile, Plot="None"))
      if (class(res_flowCut) == 'list'){
        data4df1 <- data.frame(fcsFileName=keyword(fcsfile)["$FIL"][[1]],
                               TubeName=keyword(fcsfile)["TUBE NAME"][[1]],
                               ExperimentName=keyword(fcsfile)["EXPERIMENT NAME"][[1]],
                               Date=toString(keyword(fcsfile)["$DATE"][[1]]),
                               SecondsAnalysed=strptime((keyword(fcsfile)["$ETIM"][[1]]), format = '%H:%M:%S')-strptime((keyword(fcsfile)["$BTIM"][[1]]), format = '%H:%M:%S'),
                               UserName=keyword(fcsfile)['EXPORT USER NAME'][[1]],
                               PlateOrTube=if(is.null(keyword(fcsfile)['WELL ID'][[1]])) "Tube" else "Plate",
                               TotalEvents=keyword(fcsfile)["$TOT"][[1]],
                               EventsRemoved=res_flowCut$data[13],
                               WorstChannel=if(is.integer(res_flowCut$worstChan)) res_flowCut$worstChan else "0",
                               stringsAsFactors=FALSE)
        data4df1['EventsRemoved'][data4df1['EventsRemoved']==""] <- 0
        return(data4df1)
      }
    }
  }
}

#run the flowCut function on the newest files and create df1
newfiles<-Filter(function(x) as.Date(file.info(x)$ctime, format = "%d-%b-%Y")>=LatestDate, files)
data4df1<-lapply(newfiles,QCfunction)
df1<-do.call("rbind", data4df1)

#Sumarise today's data
command <- "$FSO = New-Object -ComObject Scripting.FileSystemObject ; $FSO.GetFolder('D:/BDDatabase/BDData').Size"
df2 <- data.frame(DateTested=toString(format(Sys.time(), "%a %d %b %Y")),
                  DatabaseSizeGb=as.numeric(system2("powershell", args = command, stdout = TRUE))/1000000000,
                  TotalAcquisitions=nrow(df1),
                  TotalEvents=sum(as.numeric(as.character(unlist(df1['TotalEvents'])))),
                  TotalMins=sum(as.numeric(as.character(unlist(df1['SecondsAnalysed']))))/60,
                  TotalExperiments=sapply(df1['ExperimentName'], function(x) length(unique(x))),
                  TotalUsers=sapply(df1['UserName'], function(x) length(unique(x))),
                  RatioTubePlate=table(df1['PlateOrTube'])["Tube"]/table(df1['PlateOrTube'])["Plate"],
                  NumberOfBadAcquisitions=sum(as.numeric(as.character(unlist(df1['EventsRemoved']))) > 10),
                  stringsAsFactors=FALSE)

#subset df1 looking for the bad data
df3<-subset(df1, as.numeric(as.character(unlist(df1['EventsRemoved']))) > 10)
badfilelist<-paste("D:/BDDatabase/BDData/", df3[[1]], sep="")
worstchannellist<- df3[[10]]

#function for plotting
BadFilePlot<- function(badfilelist, worstchannellist){
  if (file.exists(badfilelist)) {
    toplot<-read.FCS(badfilelist)
    trans <- estimateLogicle(toplot, colnames(toplot[,as.integer(worstchannellist)]))
    fcsfile_trans <- transform(toplot, trans)
    png(paste(imageLocation,keyword(fcsfile_trans)["$FIL"][[1]],".png", sep = ""))
    plotDens(fcsfile_trans, c(1,as.integer(worstchannellist)),cex=5,main=keyword(fcsfile_trans)["$FIL"][[1]])
    dev.off()
  } 
}

#OUTPUT
#plot bad files
if (length(worstchannellist) > 0) {
  mapply(BadFilePlot, badfilelist, worstchannellist)
  }

#create csv of today's results
filename<- paste(csvOUT,format(Sys.time(), "%d%b%Y"),".csv",sep="")
write.csv(as.matrix(df1), file = filename)

#create or append summary data
filename<-paste(csvOUT,"Summary",".csv", sep="")
if (file.exists(filename)) {
  write.table(df2, file = filename ,append=T, sep = ",", col.names=FALSE,row.names=T)
} else {
  write.table(df2, file = filename , sep = ",",row.names=T,col.names=NA)
}

#create email table or text
if (exists("df3") & nrow(df3) >0 & exists("df2") & nrow(df2) >0){
  write(paste("<b>Problamatic files</b><br>",print(xtable(df3),type = "html"),"<br><br>","<b>Today's Summary</b><br>",print(xtable(df2), type = "html")), file = paste(csvOUT,"tosend.txt",sep=""))
} else if (!(exists("df3")) & exists("df2") & nrow(df2) >0) {
  write(paste("<b>There are no problamatic files today</b><br><br><br>","<b>Today's Summary</b><br>",print(xtable(df2), type = "html")), file = paste(csvOUT,"tosend.txt",sep=""))
} else if (!(exists("df2"))){
  write("There were no files to process today", file = paste(csvOUT,"tosend.txt",sep=""))
}else if (exists("df3") & nrow(df3) == 0 & exists("df2") & nrow(df2) >0) {
  write(paste("<b>There are no problamatic files today</b><br><br><br>","<b>Today's Summary</b><br>",print(xtable(df2), type = "html")), file = paste(csvOUT,"tosend.txt",sep=""))
}  else if (exists("df3") & nrow(df3) == 0 & exists("df2") & nrow(df2) == 0) {
  write("<b>There were no files to process today</b><br><br><br>")
}
