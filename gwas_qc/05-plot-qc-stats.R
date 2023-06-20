library(ggplot2)

data = read.csv("/storage/cleaning/ckdgenR5/00_SUMMARY/qc-stats.csv")


for (pheno in unique(data$PHENO)) {
  print(pheno)
  my_width <- sum(data$PHENO == pheno,na.rm=TRUE)/1.5 # fine tune factor
  pdf(paste0("/storage/cleaning/ckdgenR5/00_SUMMARY/plots/Assoc-QC-", pheno, "-plots.pdf"),width=my_width)
  pheno_data = data[data$PHENO == pheno,]
  
  for (var in c("PVALUE", "BETA", "STDERR", "IMP_QUALITY", "EFF_ALL_FREQ")) {
  for (qual in c("HQ", "ALL", "ZOOM")) {
  
    do_zoom = F
  # LAMBDA, SAMPLE SIZE
    if (qual == "ZOOM") {
      if (var != "BETA") {
        next
      }
      qual = "HQ"
      do_zoom = T
    }

  dat_gg <- data.frame(Study = paste(pheno_data$STUDY, pheno_data$POP, sep=" "),    
                       Min = pheno_data[, paste0(var, "_MIN_", qual)],
                       Q1 = pheno_data[, paste0(var, "_Q1_", qual)],
                       Med = pheno_data[, paste0(var, "_MED_", qual)],
                       Q3 = pheno_data[, paste0(var, "_Q3_", qual)],
                       Max = pheno_data[, paste0(var, "_MAX_", qual)],
                       N = pheno_data$SAMPLE_SIZE)
  
  if (var == "BETA") {
    text_y_pos = min(dat_gg$Min, na.rm = TRUE) - 1 
    do_n_label = T
  } else {
    do_n_label = F
  }
  
  qPlot <- ggplot(dat_gg,                             
                  aes(x = Study,
                      ymin = Min,
                      lower = Q1,
                      middle = Med,
                      upper = Q3,
                      ymax = Max)) +
    geom_boxplot(stat = "identity") +
    theme_light() +
    xlab(NULL) + 
    ylab(paste0(pheno, ", ", var, ", ", qual)) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  
  if (do_zoom) {
    qPlot = qPlot  +
      ylab(paste0(pheno, ", ", var, ", ", qual, " (zoomed)")) +
      coord_cartesian(ylim=c(min(c(dat_gg$Q1, -0.25)),max(c(dat_gg$Q3, 0.25))))
  } else {
    if (do_n_label) {
      qPlot = qPlot + 
        annotate("text", 
               x = c(1:nrow(dat_gg)), 
               y = text_y_pos,
               label = c(paste0("n=", dat_gg$N)), 
               size = 2.5)
    }
  }
   
  print(qPlot)
  
    }
  }
  
  dev.off()
  
}
