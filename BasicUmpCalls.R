library(baseballr) 
library(tidyverse)

# 745248 - 6/10 gameId
# Seemed like a lot of balls & strikes that were on the edge and inconsistent.
# Led to Cal Raleigh almost getting ejected, and he proceeded to hit a walk off grand slam next AB
pitches <- mlb_pbp(745248) |> filter(type == "pitch")
roster_mariners <- mlb_rosters(team_id = 136, season=2024, roster_type = "fullSeason")
pitches_to_mariners <- pitches |> filter(matchup.batter.id %in% roster_mariners$person_id)
pitches_to_wsox <- pitches |> filter(!(matchup.batter.id %in% roster_mariners$person_id))

# How many in the strike zone, but called ball
pitches |> filter(pitchData.zone %in% 1:9 ) |> group_by(details.isBall) |> count() |> as.data.frame()
# How many outside the strike zone, but called a strike
pitches |> filter(!(pitchData.zone %in% 1:9)) |> group_by(details.isStrike) |> count() |> as.data.frame()

# Any team benefit more/less?
# Mariners
pitches_to_mariners |> filter(pitchData.zone %in% 1:9 ) |> group_by(details.isBall) |> count() |> as.data.frame()
pitches_to_mariners |> filter(!(pitchData.zone %in% 1:9)) |> group_by(details.isStrike) |> count() |> as.data.frame()
# White Sox
pitches_to_wsox |> filter(pitchData.zone %in% 1:9 ) |> group_by(details.isBall) |> count() |> as.data.frame()
pitches_to_wsox |> filter(!(pitchData.zone %in% 1:9)) |> group_by(details.isStrike) |> count() |> as.data.frame()

# TODO: Update to handle the per-player strike zone? And the edge of the baseball on the zone vs. the center 
