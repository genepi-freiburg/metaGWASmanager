library(dplyr)
library(tidyr)
library(ggplot2)
require(lattice)



qt <- read.table("qt-summaries.txt", header = T)
qt <- qt[order(qt$study),]


colnames(qt) <- sub("_min", "__min", colnames(qt))
colnames(qt) <- sub("_q1", "__q1", colnames(qt))
colnames(qt) <- sub("_med", "__med", colnames(qt))
colnames(qt) <- sub("_q3", "__q3", colnames(qt))
colnames(qt) <- sub("_max", "__max", colnames(qt))
colnames(qt) <- sub("_n", "__n", colnames(qt))
#colnames(qt) <- sub("_na", "__na", colnames(qt))
colnames(qt) <- sub("_mean", "__mean", colnames(qt))
colnames(qt) <- sub("_sd", "__sd", colnames(qt))
colnames(qt) <- sub("_kurtosis", "__kurtosis", colnames(qt))
colnames(qt) <- sub("_skewness", "__skewness", colnames(qt))

pdf("qt_summary_joined.pdf",width=15,height=9)

i=2
while (i <= (ncol(qt)-10)) {
  data <- qt[,i:(10+i)]

  phe <- unique(sapply(strsplit(colnames(data),"__", fixed = TRUE), `[`, 1))

  colnames(data) <- c(unique(sapply(strsplit(colnames(data),"__", fixed = TRUE), `[`, 2)))


  dat_gg <- data.frame(Study = paste(qt$study,c(paste0("(","NNA=",data$n,", ","NA=",data$na,")")), sep = "/"),    
                       Min = data$min,
                       Q1 = data$q1,
                       Med = data$med,
                       Q3 = data$q3,
                       Max = data$max,
                       N = data$n,
                       miss = data$na,
                       group = c(1:nrow(data)))


  qPlot <- ggplot(dat_gg,                             
                  aes(x =Study,
                      ymin = Min,
                      lower = Q1,
                      middle = Med,
                      upper = Q3,
                      ymax = Max)) +
    geom_boxplot(stat = "identity",aes(group = group))+
    ylab(phe)+
    xlab("study")+
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 6))
   # annotate("text", x = c(1:nrow(qt)), y = max(qt[,paste0(phe,"__max")],na.rm = TRUE)+1, label = c(paste0("(","NNA=",dat_gg$N,", ","NA=",dat_gg$miss,")")),  size=2.5)
    

  print(qPlot)
  
  i=i+11
}

