args = commandArgs(trailingOnly = T)

infn = args[1]
outfn = args[2]

data = read.csv(infn)
library(openxlsx)
write.xlsx(data, outfn)
