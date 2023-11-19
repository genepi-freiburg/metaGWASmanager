library(GWASinspector)
job <- setup_inspector("config.ini")
job
job <- run_inspector(job)

#Caution: Depending on the GWASinspector version, functions may change to
#"setup.inspector" and "run.inspector"
