library(tidyverse)
library(baseballr)
library(shiny)
library(bslib)

# Helper function to get the most similar pitchers from the data files in the repo
topNPitcherSims <- function(n = 10, id) {
    sims <- read_csv(paste0("../pitcher_sims_csv/pitcher_sims_", Sys.Date() - 1, ".csv"), show_col_types = FALSE)
    names(sims)[1] <- "pitcher"
    
    # Convert from wide format to long list, and then select the top 10
    sims |> 
        filter(pitcher == id) |>
        select(-"pitcher") |>
        pivot_longer(cols = everything()) |> 
        arrange(desc(value)) |>
        slice(1:n) |>
        rename(pitcher = name, score = value)
}

# Helper function to get the list of games for today
getGames <- function(date = Sys.Date()) {
    mlb_schedule(season = 2024, level_ids = "1") |>
        filter(date == {{ date }}) |>
        select(game_pk, teams_away_team_id, teams_away_team_name, teams_home_team_id, teams_home_team_name)
}

# Get list of today's games, and build a structure of IDs with readable labels 
games <- getGames()
game_titles <- paste(games$teams_away_team_name, "@", games$teams_home_team_name)
game_ids <- games$game_pk
names(game_ids) <- game_titles

# UI layout definition
ui <- fluidPage(
    
    titlePanel("Today's Games"),
    
    # Sidebar with drop-downs for Game, Starting Pitcher, and Batting lineups  
    sidebarLayout(
        sidebarPanel(
            selectInput("game_id",
                        "Game",
                        choices = game_ids),
            selectInput("pitcher",
                        "Starting pitcher",
                        choices = NULL),
            selectInput("batter",
                        "Select batter",
                        choices = NULL)
        ),

        # Two tables: one for similar pitchers, and one for at bats against those pitchers
        mainPanel(
           fluidRow(
               column(12,
                      h3("Similar pitchers"),
                      tableOutput("pitcher_sims"))
           ),
           fluidRow(
               column(12,
                      h3("At bats against similar pitchers"),
                      tableOutput("batter"))
           )
        )
    )
)

# Server function handling all back-end operations
server <- function(input, output) {

    # Place to store various useful data structures  for each server session 
    game_vars <- reactiveValues()
    
    # Collect selected game details 
    game <- reactive({
        req(input$game_id)
        filter(games, game_pk == input$game_id)
    })
    
    # Get the pitchers and lineup info when notified of new game selection 
    observeEvent(game(), {
        # Get the probable pitchers and add them to drop down in left nav
        probables <- mlb_probables(game()$game_pk)
        choices <- probables$id 
        names(choices) <- probables$fullName
        updateSelectInput(inputId = "pitcher", choices = choices)
        
        # Get the home/away teams
        game_vars$home_team <- games |> 
            filter(game()$game_pk == game_pk) |> 
            select(id = teams_home_team_id, name = teams_home_team_name) 
        game_vars$away_team <- games |> 
            filter(game()$game_pk == game_pk) |> 
            select(id = teams_away_team_id, name = teams_away_team_name) 
        
        # Get the home/away pitchers
        game_vars$home_pitcher <- probables |> 
            filter(team_id == game_vars$home_team$id)
        game_vars$away_pitcher <- probables |> 
            filter(team_id == game_vars$away_team$id)
        
        # Get the home/away batting lineups
        lineups <- mlb_batting_orders(game()$game_pk)
        game_vars$home_lineup <- lineups |> filter(team == "home")
        game_vars$away_lineup <- lineups |> filter(team == "away")
        
    })
    
    pitcher <- reactive({
        # Just pass the selected pitcher ID through. Probably a better way
        input$pitcher
    })
    
    # When a new pitcher is selected get the batting lineup for the other team
    # and the list of similar pitchers for the selection. Update the drop-downs
    observeEvent(pitcher(), {
        req(input$pitcher)
        
        # Home team pitcher selected, grab the Away batting order. vice versa
        if(input$pitcher == game_vars$home_pitcher$id) {
            choices <- game_vars$away_lineup$id
            names(choices) <- game_vars$away_lineup$fullName
        } else {
            choices <- game_vars$home_lineup$id
            names(choices) <- game_vars$home_lineup$fullName
        }
        updateSelectInput(inputId = "batter", choices = choices)

        pitcher_sims <- topNPitcherSims(n = 10, id = input$pitcher)
        pitcher_sims$pitcher <- as.numeric(pitcher_sims$pitcher)
        pitcher_sims <- pitcher_sims |> 
            inner_join(mlb_people(pitcher_sims$pitcher), by = join_by(pitcher == id)) |> 
            select(pitcher, score, full_name)
        game_vars$pitcher_sims <- pitcher_sims
    })
    
    # When a batter is selected look for any at-bats against the similar pitchers this year
    batter <- reactive({
        req(input$batter)
        statcast_search_batters("2024-03-28", Sys.Date() - 1, input$batter) |>
            filter(pitcher %in% game_vars$pitcher_sims$pitcher)
    })

    # Render table of similar pitchers, including just the name and score. 
    # Would be useful to add the pitcher's current team
    output$pitcher_sims <- renderTable({
        pitcher()
        game_vars$pitcher_sims |>
            select(full_name, score)
    }, digits = 4)
    
    # Perform some basic manipulation on the at-bats, grouping, counting pitches, etc.
    output$batter <- renderTable({
        # Group all the pitches for an at bat
        summary_at_bats <- batter() |> 
            group_by(game_pk, at_bat_number) |> 
            select(game_pk, game_date, at_bat_number, des, pitcher)
        
        # Add the pitcher id and name to each row
        summary_at_bats <- summary_at_bats |> 
            inner_join(mlb_people(summary_at_bats$pitcher), by = join_by(pitcher == id)) |>
            select(game_pk, game_date, pitcher, at_bat_number, des, pitcher_name = full_name)
        
        # Keep just one row for each at bat - the rest are redundant
        summary_at_bats <- summary_at_bats |> 
            distinct()
        
        # Calculate the number of pitches for the at bat
        at_bat_pitch_counts <- batter() |> 
            filter(game_pk %in% summary_at_bats$game_pk) |> 
            group_by(game_pk, at_bat_number) |>
            summarise(pitches = max(pitch_number))
        
        # Add pitch count to the data frame we're building
        summary_at_bats <- summary_at_bats |>
            inner_join(at_bat_pitch_counts)
        
        # Select just the things we want to display in the UI. i.e., drop the IDs
        summary_at_bats |> 
            ungroup() |>
            select(game_date, at_bat_number, pitcher_name, pitches, des) |>
            mutate(across(game_date, as.character))
        
    }, digits = 0)
}

# Run the application 
shinyApp(ui = ui, server = server)
