parameters = data.frame()
bt_summaries = data.frame()
qt_summaries = data.frame()

collect_parameters = function(fn, row_idx, parameters) {
	params_pattern = "parameters"
	params_fn = list.files(paste0("../", fn), pattern=params_pattern)

	# temp workaround
	if (length(params_fn) == 0) {
		my_name = unlist(strsplit(fn, "_", fixed=T))
		my_name_nodate = my_name[1:length(my_name)-1]
		study_name = paste(my_name_nodate, collapse="_")
		parameters[row_idx, "study_name"] = study_name
		print(paste("WARNING: return GUESSED study name:", study_name))
		return(parameters)
	}

	if (length(params_fn) != 1) {
		stop(paste0("expect single parameters file, but got zero or multiple: ", params_fn, sep="", collapse=";"))
	}
	print(paste0("read parameters file: ", params_fn))

	params_path = paste0("../", fn, "/", params_fn)
	data = read.table(params_path, h=T)
	
	if (!any("key" %in% colnames(data))) {
		print("format unknown, try original format")

		data = read.table(file = params_path, 
                        header = F, 
                        col.names = c("key", "value"),
                        stringsAsFactors = F,
                        colClasses = c("character", "character"))
	}

	print(paste0("got parameters: ", nrow(data)))

	for (kv_idx in 1:nrow(data)) {
		key = data[kv_idx, "key"]
		value = data[kv_idx, "value"]
		parameters[row_idx, key] = value
	}
	return(parameters)
}

collect_bts = function(fn, row_idx, bt_summaries, study) {
	bt_fn = list.files(paste0("../", fn), pattern="*_bt_summary.txt")
        if (length(bt_fn) != 1) {
                stop(paste0("expect single BT summary file, but got zero or multiple: ", bt_fn, sep="", collapse=";"))
        }
        print(paste0("read BT summary file: ", bt_fn))
        data = read.table(paste0("../", fn, "/", bt_fn), h=T)
        print(paste0("got BT summaries: ", nrow(data)))

	bt_summaries[row_idx, "study"] = study

        for (var_idx in 1:nrow(data)) {
                var = data[var_idx, "variable"]
                bt_summaries[row_idx, paste0(var, "_n")] = data[var_idx, "n"]
                bt_summaries[row_idx, paste0(var, "_na")] = data[var_idx, "na"]
                if (var != "sex") {
                        bt_summaries[row_idx, paste0(var, "_no")] = data[var_idx, "no_or_male"]
                        bt_summaries[row_idx, paste0(var, "_yes")] = data[var_idx, "yes_or_female"]
                } else {
                        bt_summaries[row_idx, paste0(var, "_male")] = data[var_idx, "no_or_male"]
                        bt_summaries[row_idx, paste0(var, "_female")] = data[var_idx, "yes_or_female"]
                }
        }

	return(bt_summaries)
}

collect_qts = function(fn, row_idx, qt_summaries, study) {
        qt_fn = list.files(paste0("../", fn), pattern="*_qt_summary.txt")
        if (length(qt_fn) != 1) {
                stop(paste0("expect single QT summary file, but got zero or multiple: ", qt_fn, sep="", collapse=";"))
        }
        print(paste0("read QT summary file: ", qt_fn))
        data = read.table(paste0("../", fn, "/", qt_fn), h=T)
        print(paste0("got QT summaries: ", nrow(data)))

        qt_summaries[row_idx, "study"] = study

        for (var_idx in 1:nrow(data)) {
                var = data[var_idx, "variable"]
                for (stat in c("min", "q1", "med", "q3", "max", "n", "na", "mean", "sd", "kurtosis", "skewness")) {
                        qt_summaries[row_idx, paste0(var, "_", stat)] = data[var_idx, stat]
                }
        }

	return(qt_summaries)
}

row_idx = 0
for (fn in list.files("..")) {
	if (fn != "00_SUMMARY" && fn != "00_ARCHIVE") {
		row_idx = row_idx + 1
		print(paste0("===== Collect: ", fn, " (#", row_idx, ")"))
		parameters = collect_parameters(fn, row_idx, parameters)
		study = parameters[row_idx, "study_name"]
		ancestry = parameters[row_idx, "ancestry"]
		study = paste(study, ancestry, sep="_")
		bt_summaries = collect_bts(fn, row_idx, bt_summaries, study)
		qt_summaries = collect_qts(fn, row_idx, qt_summaries, study)
	}
}

write.table(parameters, "parameter-summary.txt", row.names=F, col.names=T, sep="\t", quote=F)
write.table(bt_summaries, "bt-summaries.txt", row.names=F, col.names=T, sep="\t", quote=F)
write.table(qt_summaries, "qt-summaries.txt", row.names=F, col.names=T, sep="\t", quote=F)

#print(parameters)
