library(baseballr)
library(abdwr3edata)
library(tidyverse)
options(dplyr.summarise.inform=F)

# Import all of the available Statcast data for the year
statcast <- statcast_read_csv(dir = "./statcast_csv")

# Augment with an indicator as to whether a hit or out occurred 
hit_events <- c("single", "double", "triple", "home_run")
out_events <- c("double_play", "field_error", "field_out", "fielders_choice_out",
                "force_out", "grounded_into_double_play", "other_out", "strikeout", 
                "strikeout_double_play", "triple_play")
statcast <- statcast %>% 
  mutate(H = ifelse(events %in% hit_events, 1, 0),
         O = ifelse(events %in% out_events, 1, 0))

# Get all the batters across the league yesterday
yesterday <- Sys.Date() - 1
batters <- statcast |> 
  filter(game_date == yesterday) |> 
  select(batter, player_name) |> 
  unique()


# Given player ID, date, and number N, calculate the batting average
# Over the N games prior to the given date. 
# If N == NULL, then calculate for all prior games this year
get_trailing_batting_avg <- function(player_id, date, N = NULL) {
  # Extract just this player's at bat data
  player_data <- statcast |> filter(batter == player_id)
  
  # Group by plate appearance, indicating whether it ended with a hit our an out
  player_data <- player_data |> 
    group_by(game_date, game_pk, at_bat_number) |> 
    summarise(H = sum(H), O = sum(O)) 
  
  # Get the date for the last N games the player has been in the lineup
  player_game_dates <- player_data |>
    arrange(desc(game_date)) |>
    ungroup() |>
    select(game_date) |>
    unique() |>
    slice(1:ifelse(is.null(N), n(), N))
  
  # Further subset the players at bats to the last N games
  trailing_pas <- player_data |> 
    filter(game_date %in% player_game_dates$game_date)
  
  # Calculate their batting average over that time
  trailing_avg <- sum(trailing_pas$H) / (sum(trailing_pas$H) + sum(trailing_pas$O))
  round(trailing_avg,3)
}


# Calculate the season average for all the players who hit yesterday
season_avg <- lapply(batters$batter, get_trailing_batting_avg, yesterday, NULL)
season_avg <- as.data.frame(do.call(rbind,season_avg))

# Get their 3-, 5-, and 7-day trailing averages
trailing_avg_3 <- lapply(batters$batter, get_trailing_batting_avg, yesterday, 3)
trailing_avg_5 <- lapply(batters$batter, get_trailing_batting_avg, yesterday, 5)
trailing_avg_7 <- lapply(batters$batter, get_trailing_batting_avg, yesterday, 7)

# Merge it all into a single data frame 
batting_avgs <- cbind(Sys.Date(),
                      batters, 
                      season_avg, 
                      as.data.frame(do.call(rbind,trailing_avg_3)),
                      as.data.frame(do.call(rbind,trailing_avg_5)),
                      as.data.frame(do.call(rbind,trailing_avg_7)))
colnames(batting_avgs) <- c("date", "player_id", "name", "avg", "avg_3", "avg_5", "avg_7")

# Calculate the deltas from the season average
batting_avgs$delta_3 <- batting_avgs$avg_3 - batting_avgs$avg
batting_avgs$delta_5 <- batting_avgs$avg_5 - batting_avgs$avg
batting_avgs$delta_7 <- batting_avgs$avg_7 - batting_avgs$avg

# Write a CSV of the data file that was calculated
write.csv(batting_avgs, file = paste0("hot_cold_csv/hot_cold_", Sys.Date(), ".csv"), row.names = FALSE)


