#' @export
summary_statement_ui <- function(
    id,
    title = "Summary"
) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bslib::card(
      title = title,
      shiny::tags$div(
        id = ns("summary"),
        ""
      )
    )
  )
}

#' @export
summary_server <- function(
    id,
    df,
    date_column = "date", # Add a date_column argument with a default value of "date"
    selected_date = NULL # Add a selected_date argument with a default value of NULL
) {
  shiny::moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      output$summary <- shiny::renderText({
        # If selected_date is not provided, use the maximum date from the DataFrame
        if (is.null(selected_date)) {
          selected_date <- max(df[[date_column]], na.rm = TRUE)
        }

        # Filter the data for the selected date
        df_filtered <- df[df[[date_column]] == selected_date, ]

        # Calculate the total number of cases for the selected date
        total_cases <- nrow(df_filtered)

        # Create the statement
        statement <- glue::glue("As of {selected_date}, the total number of cases is {total_cases}.")

        statement
      })
    }
  )
}
