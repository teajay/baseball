# Downloads 2024 Statcast data and stores it in the 'statcast_csv' directory
# Skips days that are already there, so it can incrementally update the folder 
# as part of a scheduled job that runs daily

library(abdwr3edata)

season_begin <- as.Date("2024-03-28")
output_directory <- "./statcast_csv"

# List of days since the season began
dates <- seq(season_begin, Sys.Date() - 1, by="days")

# Expected filenames for statcast data. e.g., "./sc_2024-06-16.csv"
filenames <- paste0(output_directory, "/sc_", dates, ".csv")

# Which ones exists already
exists <- file.exists(filenames)

# List of days that we need to download
dates_to_download <- dates[exists == FALSE]

# Download them
lapply(dates_to_download, statcast_daily, dir = output_directory)
