#' @export
summary_statement_ui <- function(
    id,
    title = "Summary"
) {
  ns <- shiny::NS(id)

  bslib::card(
    title = title,
    bslib::card_text(
      id = ns("summary"), # Use the same id as in the server function
      ""
    )
  )
}

#' @export
summary_server <- function(
    id,
    df
) {
  shiny::moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      output$summary <- shiny::renderText({
        # Get the most updated date from the DataFrame (assuming there's a date column named "date")
        most_updated_date <- max(df$date, na.rm = TRUE)

        # Calculate the total number of cases
        total_cases <- nrow(df)

        # Create the statement
        statement <- glue::glue("As of {most_updated_date}, the total number of cases is {total_cases}.")

        statement
      })
    }
  )
}
