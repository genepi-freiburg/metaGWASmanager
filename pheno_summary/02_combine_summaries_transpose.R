qt = read.table("qt-summaries.txt", h=T)
bt = read.table("bt-summaries.txt", h=T)

if (nrow(qt) != nrow(bt) || any(qt$study != bt$study)) {
	stop("ERROR: qt/bt summary mismatch")
}

qt2 = data.frame(t(qt))
qt3 = qt2[-1,]
bt2 = data.frame(t(bt))
bt3 = bt2[-1,]

comb = rbind(qt3, bt3)
colnames(comb) = qt2[1,]
comb$variable = c(colnames(qt)[2:length(qt)], colnames(bt[2:length(bt)]))

write.table(comb, "summaries.txt", row.names=F, col.names=T, sep="\t", quote=F)

print(summary(comb))

