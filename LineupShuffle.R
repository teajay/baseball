library(baseballr)
library(abdwr3edata)
library(tidyverse)
options(dplyr.summarise.inform=F)

# Import all of the available Statcast data for the year
statcast <- statcast_read_csv(dir = "./statcast_csv")

# Get game ids for Mariner's regular season. 
# Status = "Final" is to skip postponed and future games
team_id_Mariners <- 136
mariners_games <- mlb_schedule(season = 2024, level_ids = "1") |>
  filter(game_type == "R" & status_detailed_state == "Final" &
         (teams_away_team_id == team_id_Mariners | teams_home_team_id == team_id_Mariners)) |>
  select(date, game_pk)

# Helper function to pull out just the Mariners side of the lineup, 
# a subset of the fields, and add the game id for joining against later
batting_order <- function(game_id) {
  mlb_batting_orders(game_id, type = "starting") |>
    filter(teamID == team_id_Mariners) |> 
    mutate(game_pk = game_id) |>
    select(game_pk, player_id = id, fullName, batting_order, abbreviation)
}

# Build a list of each game and it's batting order
x <- lapply(mariners_games$game_pk, batting_order)
names(x) <- mariners_games$game_pk

# Flatten the list to a data frame, with the game date included  
lineups <- as.data.frame(do.call(rbind, x))
lineups <- mariners_games |>
  inner_join(lineups)

# Write it to Excel for ad-hoc analysis
openxlsx::write.xlsx(lineups, "lineups_2024.xlsx", colNames = TRUE)


## Part 2 - Add trailing batting average to lineup

# Filter statcast data just to the Mariners games this year
statcast <- statcast |> 
  filter(game_pk %in% mariners_games$game_pk & batter %in% lineups$player_id)

# Augment with an indicator as to whether a hit or out occurred 
hit_events <- c("single", "double", "triple", "home_run")
out_events <- c("double_play", "field_error", "field_out", "fielders_choice_out",
                "force_out", "grounded_into_double_play", "other_out", "strikeout", 
                "strikeout_double_play", "triple_play")
statcast <- statcast %>% 
  mutate(H = ifelse(events %in% hit_events, 1, 0),
         O = ifelse(events %in% out_events, 1, 0))

# Given player ID, date, and number N, calculate the batting average
# Over the N games prior to the given date
get_trailing_batting_avg <- function(player_id, date, N) {
  # Extract just this player's at bat data
  player_data <- statcast |> filter(batter == player_id)
  
  # Group by plate appearance, indicating whether it ended with a hit our an out
  player_data <- player_data |> 
    group_by(game_date, game_pk, at_bat_number) |> 
    summarise(H = sum(H), O = sum(O)) 
  
  # Get the date for the last N games the player has been in the lineup
  player_game_dates <- lineups |> 
    filter(player_id == {{ player_id }} & date < {{ date }}) |> 
    arrange(desc(date)) |> 
    select(date) |> 
    top_n(N)
  
  # Further subset the players at bats to the last N games
  trailing_pas <- player_data |> 
    filter(game_date %in% player_game_dates$date)
  
  # Calculate their batting average over that time
  trailing_avg <- sum(trailing_pas$H) / (sum(trailing_pas$H) + sum(trailing_pas$O))
  c(player_id, round(trailing_avg,3))
}


games_since_june <- lineups |> 
  filter(date >= "2024-06-01") |> 
  select(date) |> 
  unique()

lineup_with_avg <- NULL

for(game in games_since_june$date) { 
  lineup <- lineups |> filter(date == game)
  
  # 10 game trailing average
  lineup_trailing_avg_10 <- lapply(lineup$player_id, get_trailing_batting_avg, lineup$date[1], 10)
  lineup_trailing_avg_10 <- as.data.frame(do.call(rbind,lineup_trailing_avg_10))
  colnames(lineup_trailing_avg_10) <- c("player_id", "avg_10")
  
  # 5 game trailing average
  lineup_trailing_avg_5 <- lapply(lineup$player_id, get_trailing_batting_avg, lineup$date[1], 5)
  lineup_trailing_avg_5 <- as.data.frame(do.call(rbind,lineup_trailing_avg_5))
  colnames(lineup_trailing_avg_5) <- c("player_id", "avg_5")
  
  # Append the 5 and 10 day trailing batting averages to the lineup
  lineup_with_avg <- bind_rows(lineup |> inner_join(lineup_trailing_avg_10) |> inner_join(lineup_trailing_avg_5), lineup_with_avg)
}

lineup_with_avg <- type_convert(lineup_with_avg)
openxlsx::write.xlsx(lineup_with_avg, "lineup_with_trailing_avg_since_june.xlsx", colNames = TRUE)








### --- Pivot wider ---- 
### Could be substituted, and maybe even better to export long form to Excel

# Fix data types and an rescheduled game that caused problems on widening 
#lineups <- type_convert(lineups)
#mariners_games[mariners_games$game_pk == "746572",]$date <- "2024-04-19"

#lineup_matrix <- lineups |> 
#  select(date, fullName, batting_order) |>
#  pivot_wider(names_from = fullName, values_from = batting_order, values_fill = 0)

### --- End Pivot wider ----


