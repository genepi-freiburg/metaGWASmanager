args = commandArgs(trailingOnly = T)

infn = args[1]
outfn = args[2]

data = read.csv(infn)
library(openxlsx)
# TODO apply formatting
write.xlsx(data, outfn)
