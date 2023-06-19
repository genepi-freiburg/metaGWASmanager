library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
fl = args[1]
tit = args[2]
ofn = args[3]

print(paste0("reading: ", fl))
print(paste0("title: ", tit))
print(paste0("output: ", ofn))

connection = gzfile(fl, "rt")
data = read.table(connection, h = T)
close(connection)

row_count = nrow(data)
print(paste0("got rows: ", row_count))

print(summary(data))

corr = round(cor(data$STUDY_FREQ, data$REF_FREQ, method="pearson"), 2)
print(paste0("Pearson correlation coefficient: ", corr))

pdf(ofn)

ggplot(data, aes(x=STUDY_FREQ, y=REF_FREQ)) +
  labs(title = paste("Frequency Comparison:", tit),
       subtitle = paste0("n(variants) = ", row_count, "; Pearson correlation coefficient = ", corr)) +
  geom_bin2d(bins = 400) +
  xlab("Study Frequency") +
  ylab("Reference Frequency") +
  scale_fill_continuous(type = "viridis", trans = "log", name="log10(count)") +
  theme_bw()

dev.off()
