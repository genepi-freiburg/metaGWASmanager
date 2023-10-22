library(dplyr)
library(tidyr)
library(ggplot2)
require(lattice)



ids <- read.delim("ids-summaries.txt", header = T)
ids <- ids[order(ids$study),]


colnames(ids) <- sub("_min", "__min", colnames(ids))
colnames(ids) <- sub("_q1", "__q1", colnames(ids))
colnames(ids) <- sub("_med", "__med", colnames(ids))
colnames(ids) <- sub("_q3", "__q3", colnames(ids))
colnames(ids) <- sub("_max", "__max", colnames(ids))
colnames(ids) <- gsub("([^_])_n$", "\\1__n", colnames(ids))
colnames(ids) <- sub("_na", "__na", colnames(ids))
colnames(ids) <- sub("_mean", "__mean", colnames(ids))
colnames(ids) <- sub("_sd", "__sd", colnames(ids))
colnames(ids) <- sub("_kurtosis", "__kurtosis", colnames(ids))
colnames(ids) <- sub("_skewness", "__skewness", colnames(ids))
colnames(ids) <- sub("_cat1", "__cat1", colnames(ids))
colnames(ids) <- sub("_cat2", "__cat2", colnames(ids))
colnames(ids) <- sub("_cat3", "__cat3", colnames(ids))
colnames(ids) <- sub("_categories", "__categories", colnames(ids))


pdf("ids_summary_joined.pdf",width=15,height=9)

i=2
while (i <= (ncol(ids)-14)) {
  data <- ids[,i:(14+i)]
  phe <- unique(sapply(strsplit(colnames(data),"__", fixed = TRUE), `[`, 1))

  colnames(data) <- c(unique(sapply(strsplit(colnames(data),"__", fixed = TRUE), `[`, 2)))
  
  data$Study<-ids$study
  data<- data[rowSums(is.na(data)) < ncol(data)-1, ]
  

  if(all(!is.na(data[, c("min", "q1", "med")]))) {
    dat_gg <- data.frame(Study = paste(data$Study,c(paste0("(","NNA=",data$n,", ","NA=",data$na,")")), sep = "/"),    
                         Min = data$min,
                         Q1 = data$q1,
                         Med = data$med,
                         Q3 = data$q3,
                         Max = data$max,
                         N = data$n,
                         miss = data$na,
                         group = c(1:nrow(data)))
    
    Plot <- ggplot(dat_gg,                             
                    aes(x =Study,
                        ymin = Min,
                        lower = Q1,
                        middle = Med,
                        upper = Q3,
                        ymax = Max)) +
      geom_boxplot(stat = "identity",aes(group = group))+
      ylab(phe)+
      xlab("Study")+
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 6))
    # annotate("text", x = c(1:nrow(ids)), y = max(ids[,paste0(phe,"__max")],na.rm = TRUE)+1, label = c(paste0("(","NNA=",dat_gg$N,", ","NA=",dat_gg$miss,")")),  size=2.5)
    
  } else {
    dat_cat <- data.frame(Study = paste(data$Study,c(paste0("(","NNA=",data$n,", ","NA=",data$na,")")), sep = "/"),    
                        cat1= data$cat1,
                        cat2= data$cat2,
                        cat3= data$cat3,
                        categ=data$categories,
                        N = data$n,
                        miss = data$na,
                        group = c(1:nrow(data)))
    
    dat_cat$pct_1 <- (dat_cat$cat1 / dat_cat$N) * 100
    dat_cat$pct_2 <- (dat_cat$cat2 / dat_cat$N) * 100
    dat_cat$pct_3 <- (dat_cat$cat3 / dat_cat$N) * 100
    
    dat_gg <- tidyr::gather(dat_cat, key = "categorie", value = "percentage", pct_1, pct_2, pct_3)
    
    #Add real categories label
    categories<- unique(unlist(strsplit(gsub("[^A-Za-z]", "", dat_cat$categ), "")))

    dat_gg$categorie[ dat_gg$categorie == "pct_1"] <- categories[1]
    dat_gg$categorie[ dat_gg$categorie == "pct_2"] <- categories[2]
    dat_gg$categorie[ dat_gg$categorie == "pct_3"] <- categories[3]
    
    
    Plot<-  ggplot(dat_gg, aes(x = Study, y = percentage, fill = categorie)) +
      geom_col(position = "stack") +
      ylab("Percentage (%)") +
      ggtitle(phe) +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 7))
 
  }


  print(Plot)
  
  i=i+15
}

dev.off()
