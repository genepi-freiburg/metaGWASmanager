gsheet_url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjwLVm9EI9mpOOIyt3zdSH9l5_nyjckvtnZBtASFdw-fToluOPIU-CEIWw_xdeqdd7ry2SbLzPd-Zx/pub?output=csv"
qc_stats_file = "/storage/cleaning/ckdgenR5/00_SUMMARY/qc-stats.csv"


data = read.csv(gsheet_url)
print(paste0("Google Sheet rows: ", nrow(data)))

gsheet_studies = unique(data$Study)
print(paste0("Google Sheet n(studies): ", length(gsheet_studies)))

qc = read.csv(qc_stats_file)
print(paste0("QC Stats rows: ", nrow(qc)))
qc_studies = unique(qc$STUDY)
print(paste0("QC Stats n(studies): ", length(qc_studies)))

#cat(paste0("GSheet:\n", paste(gsheet_studies, collapse="\n")))
#cat(paste0("QC Stats:\n", paste(qc_studies, collapse="\n")))

miss1 = which(!(qc_studies %in% gsheet_studies))
print(paste0("Studies missing in GSheet: ", paste(qc_studies[miss1], collapse=", ")))

miss2 = which(!(gsheet_studies %in% qc_studies))
print(paste0("Studies missing in QC Stats: ", paste(gsheet_studies[miss2], collapse=", ")))

