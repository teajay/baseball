Sandbox for baseball analytics. Contains a handful of different mini-projects. Often geared towards the Seattle Mariners, but some scripts have been generalized. 

# StatcastDownload
Downloads daily Statcast files and stores it in the statcast_csv folder of this repo. Connected to a GitHub action that runs daily.

# PitcherSims
Uses the Statcast data in this repo to generate a matrix of similarity scores between each pitcher. End result is symmetric matrix, with 1s on the diagonal -- similar to a correlation matrix. Produces a CSV file with the matrix that can be used in other scripts.

# Matchups
Basic Shiny application that uses the PitcherSims data. Displays a list of today's games and allows you to select a batter from one of the lineups. A very crude view of their at bat history against today's starter and similar pitchers this year is displayed.  

# MonthlyLongBalls
Plot the ratio of home runs to deep fly balls in the outfield. The hypothesis was that earlier in the year there were fewer home runs here in Seattle vs Away. The current implementation looking at 2023 data was inconclusive, since the field regions used by Retrosheets are quite large. This should be migrated to use statcast data so we can get more precise batted ball location - e.g., plot home runs vs warning tracks.

# BasicUmpCalls
A one-off look at a game from June 10, when Cal Raleigh nearly got ejected for arguing a call. Looks at the number of pitches in the zone that were called ball, and vice versa. Split up by each team to see if calls favored one team or another. In the future this should be extended to look at more games, use per-batter strike zones from Statcast instead of the generic Game Day zones, and the edge of the baseball instead of the center. 

# LineupShuffle
Collects the Mariners batting order for each game of the season, calculates trailing 5-, and 10-day batting average and exports it all to Excel. Can be used to create different pivot tables that let you get a sense if there are any discernible patterns. 

# HotColdStreaks
Calculates the season batting average, 3-, 5-, and 7-day trailing averages for everyone who had a plate appearance on a given day and writes a CSV file to the hot_cold_csv directory here. Was using this data as a companion to the LineupShuffle above to see if there were lineup changes based on short-term performance. 

# Pitch Prediction
TensorFlow neural network that attempted to predict pitch types based on game state variables. Proved to be unsuccessful at making predictions. The Jupyter notebook output is hosted over on GitHub Pages (https://teajay.github.io/pitch-prediction.html), and the .ipynb file is checked into this repo.  
