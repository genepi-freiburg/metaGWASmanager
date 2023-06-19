library(dplyr)
library(tidyr)
library(ggplot2)
require(lattice)

bt <- read.table("bt-summaries.txt", header = T)
bt <- bt[order(bt$study),]

colnames(bt) <- sub("_n", "__n", colnames(bt),fixed = TRUE)
#colnames(bt) <- sub("_na", "__na", colnames(bt),fixed = TRUE)
colnames(bt) <- sub("_male", "__male", colnames(bt))
colnames(bt) <- sub("_female", "__female", colnames(bt))
#colnames(bt) <- sub("_no", "__no", colnames(bt))
colnames(bt) <- sub("_yes", "__yes", colnames(bt))




pdf("bt_summary_joined.pdf",width=13,height=9)


i=3
while (i <= ncol(bt)) {
data <- gather(bt[,c(1,i:(i+2))],"Stat", "Value", -study)
phe <- unique(sapply(strsplit(data$Stat,"__", fixed = TRUE), `[`, 1))
data$pct <- paste0(round((data$Value/bt[,paste0(phe,"__n")])*100,2),"%")
data$N <- bt[,paste0(phe,"__n")]
data$miss <- bt[,paste0(phe,"__na")]
data$Study <- paste(data$study,c(paste0("(",paste0("NNA=",c(bt[,paste0(phe,"__n")])),", ",paste0("NA=",c(bt[,paste0(phe,"__na")])),")")), sep = "/")

order <- levels(as.factor(data$Stat))

bPlot <- ggplot(data, aes(x = Study, y = Value, fill = Stat)) +
  geom_col(position = "stack")+
  ylab("Sample size")+
  ggtitle(phe)+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 7))
  #annotate("text", x = c(1:nrow(bt)), y = 4e+05, label = paste0("NNA=",c(bt[,paste0(phe,"__n")])), size=3)+
  #annotate("text", x = c(1:nrow(bt)), y = 4e+05, label = paste0("NA=",c(bt[,paste0(phe,"__na")])), size=3)


print(bPlot)
i=i+4
}




dev.off()
