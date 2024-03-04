d = read.table("hg38_corrected.psam", h=F, stringsAsFactors=T)
colnames(d)= c("IID","PAT","MAT","SEX","SuperPop","Population")

nrow(d)
#[1] 3202

#summary(d)
#      IID            PAT            MAT            SEX        SuperPop
# HG00096:   1   0      :2592   0      :2589   Min.   :1.000   AFR:893
# HG00097:   1   HG00656:   2   HG00657:   2   1st Qu.:1.000   AMR:490
# HG00099:   1   HG03679:   2   HG03642:   2   Median :2.000   EAS:585
# HG00100:   1   HG03943:   2   HG03944:   2   Mean   :1.501   EUR:633
# HG00101:   1   NA19661:   2   NA19238:   2   3rd Qu.:2.000   SAS:601
# HG00102:   1   NA19679:   2   NA19660:   2   Max.   :2.000
# (Other):3196   (Other): 600   (Other): 603
#   Population
# CEU    : 179
# GWD    : 178
# YRI    : 178
# CHS    : 163
# IBS    : 157
# ESN    : 149
# (Other):2198

#rs4293393_A

geno = read.table("extract_rs4293393.raw", h=T, stringsAsFactors=T)
geno2 = data.frame(IID=geno$IID, rs4293393_A=geno$rs4293393_A)
summary(geno2)
nrow(geno2)
d = merge(d, geno2)
nrow(d)

d$egfr0 = rnorm(nrow(d), 90, 20)
d$egfr1 = rnorm(nrow(d), 80, 20)
d$egfr2 = rnorm(nrow(d), 70, 20)

summary(d)

d$egfr = ifelse(d$rs4293393_A == 0, d$egfr0, ifelse(d$rs4293393_A == 1, d$egfr1, d$egfr2))
d$egfr = ifelse(d$egfr > 0, d$egfr, 0)
d$egfr0 = NULL
d$egfr1 = NULL
d$egfr2 = NULL

d$age = rnorm(nrow(d), 50, 5)
d$age = ifelse(d$age > 0, d$age, 0)

d$PC1 = rnorm(nrow(d))
d$PC2 = rnorm(nrow(d))
d$PC3 = rnorm(nrow(d))
d$PC4 = rnorm(nrow(d))
d$PC5 = rnorm(nrow(d))

d$SEX[which(d$SEX == 1)] = 'M'
d$SEX[which(d$SEX == 2)] = 'F' 
d$SEX = as.factor(d$SEX)

colnames(d)[which(colnames(d)=="PAT")] = c("FID") # rename second column from PAT to FID
d$FID = d$IID
d$MAT = NULL 
d$Population = NULL 
d$rs4293393_A = NULL

summary(d)

for (pop in levels(d$SuperPop)) {
  e = subset(d, d$SuperPop == pop)
  e$SuperPop = NULL
  write.table(e, paste0("simulated-input-", pop, ".txt"), row.names=F, col.names=T, sep="\t", quote=F)
}

