Sandbox for baseball analytics. Contains a handful of different mini-projects.

# StatcastDownload
Downloads daily Statcast files and stores it in the statcast_csv folder of this repo. Connected to a GitHub action that runs daily.

# PitcherSims
Uses the Statcast data in this repo to generate a matrix of similarity scores between each pitcher. End result is symmetric matrix, with 1s on the diagonal -- similar to a correlation matrix. Produces a CSV file with the matrix that can be used in other scripts.

# Matchups
Basic Shiny application that uses the PitcherSims data. Displays a list of today's games and allows you to select a batter from one of the lineups. A very crude view of their at bat history against today's starter and similar pitchers this year is displayed.  
