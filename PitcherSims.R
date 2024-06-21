library(abdwr3edata)
library(baseballr)
library(tidyverse)
library(lsa)

# Import all of the available Statcast data for the year
statcast <- statcast_read_csv(dir = "./statcast_csv")

# Get number of pitches per pitch type for each pitcher 
pitcher_pitch_count_by_type <- statcast |> 
  select(pitcher, pitch_name) |>
  group_by(pitcher, pitch_name) |>
  count(name = "pitch_type_count")

# Get total number of pitches thrown for each pitcher 
pitcher_pitch_total <- pitcher_pitch_count_by_type |> 
  group_by(pitcher) |>
  summarise(pitch_total = sum(pitch_type_count)) 

# Calculate the ratio of each pitch type, and filter out players with fewer than 100 pitches
pitcher_ratios <- pitcher_pitch_total |> 
  inner_join(pitcher_pitch_count_by_type, by = join_by(pitcher)) |>
  mutate(ratio = pitch_type_count / pitch_total)

# Convert from long to wide format, using zeros for pitch types that aren't thrown
pitcher_ratios_wide <- pitcher_ratios |>
  select(pitcher, pitch_name, ratio) |>
  pivot_wider(names_from = "pitch_name", names_sort = TRUE, 
              values_from = "ratio", values_fill = 0)

# Calculate cosine similarity score between each pitcher. 
# End result is symmetric matrix, with 1s on the diagonal. Similar to correlation matrix 
# 'cosine' function works on column vectors of matrices, so we take the transpose
# Drop the first column too, since that is player ID and irrelevant for similarity
cosine_similarity <- cosine(t(pitcher_ratios_wide[,2:ncol(pitcher_ratios_wide)]))

# Label rows and columns with the pitcher ID 
colnames(cosine_similarity) <- pitcher_ratios_wide$pitcher
rownames(cosine_similarity) <- pitcher_ratios_wide$pitcher

# Write the file 
write.csv(cosine_similarity, file = paste0("pitcher_sims_csv/pitcher_sims_", Sys.Date(), ".csv"))
