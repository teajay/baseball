getMonthlyHitsAndHomeRuns <- function(team, year=2023, home=TRUE, plot=TRUE) {
  data <- readRDS(paste0(as.character(year),".rds",sep=""))  
  data <- data[[as.character(year)]]
  
  # Get the team's home or away games
  if(home) {
    games <- data$events |>
      filter(startsWith(game_id, team)) |>
      mutate(month = substr(game_id,8,9))
  } else {
    games <- data$events |>
      filter(away_team_id == "SEA") |>
      mutate(month = substr(game_id,8,9))
  }
  
  # Grab all deep outfield hits and home run events
  hr_deepof_events <- games |>
    filter(grepl("HR|7LD|7D|78XD|8XD|89XD|9D|9LD",event_tx))
  
  # Filter just the outfield hits that are not home runs
  deep_hits <- hr_deepof_events |>
    filter(grepl("7LD|7D|78XD|8XD|89XD|9D|9LD",event_tx) & !grepl("HR",event_tx))
  
  # Filter just the home runs
  homeruns <- hr_deepof_events |>
    filter(grepl("HR",event_tx))
  
  # Count the hits and group by month
  deep_hit_by_month <- deep_hits |>
    group_by(month) |>
    summarise(deep_hits = n())
  
  homeruns_by_month <- homeruns |>
    group_by(month) |>
    summarise(home_runs = n())
  
  # Create a data structure to return with our summarized data 
  months <- games |>
    distinct(month)
  monthly_counts <- merge(months, deep_hit_by_month, all.x = TRUE)
  monthly_counts <- merge(monthly_counts, homeruns_by_month, all.x = TRUE)
  monthly_counts[is.na(monthly_counts)] <- 0 
  monthly_counts <- monthly_counts |> 
    mutate(home_runs_pct = home_runs / (deep_hits + home_runs))
  
  if(plot) {
    m <- as.matrix(monthly_counts)
    rownames(m) <- m[,1]
    barplot(t(m[,2:3]), xlab="Month", main=ifelse(home,paste(team,"(Home)"),paste(team,"(Away)")))
  }
  
  monthly_counts
}

#for(team in teamIDs$team) {
#  getMonthlyHitsAndHomeRuns(team=team, plot=TRUE)
#}

home <- getMonthlyHitsAndHomeRuns(team="SEA")
away <- getMonthlyHitsAndHomeRuns(team="SEA", home=FALSE)
#t <- home |>
#  select(month, home_runs_pct)
#t <- merge(t, away$home_runs, all.x = TRUE)
