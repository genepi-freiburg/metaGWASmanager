ids = read.delim("ids-summaries.txt", h=T)

ids2 = data.frame(t(ids))
comb = ids2[-1,]

colnames(comb) = ids2[1,]
comb$variable = c(colnames(ids)[2:length(ids)])

write.table(comb, "summaries.txt", row.names=F, col.names=T, sep="\t", quote=F)

print(summary(comb))

