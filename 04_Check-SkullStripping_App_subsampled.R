library(shiny)
library(tidyverse)
library(papayaWidget)

# ---- Outliers - EXCLUSION LIST ----
EXCLUDE_SUBJECTS <- c("BSCMR075")

# ---- data directory ----
data_dir <- "data_for_skullstrip"

# ---- list relevant files recursively ----
files <- list.files(
  data_dir,
  pattern = "sub-.*(desc-(preproc_T1w|brain_mask)).*\\.nii\\.gz$",
  recursive = TRUE,
  full.names = TRUE
)

message("Found ", length(files), " files in ", data_dir)

if (length(files) == 0) {
  stop("No files found! Check that data_dir path is correct.")
}

# ---- build dataframe of files ----
df <- tibble(file = files) %>%
  mutate(
    filename = basename(file),
    sub_id = str_extract(filename, "sub-[A-Za-z0-9]+")
  ) %>%
  filter(!is.na(sub_id))

message("Raw files found: ", nrow(df))
print(head(df))

# Separate native and subsampled
df_processed <- df %>%
  mutate(
    is_subsamp = str_detect(filename, "_subsamp2"),
    is_t1w = str_detect(filename, "desc-preproc_T1w"),
    is_mask = str_detect(filename, "desc-brain_mask")
  ) %>%
  mutate(
    file_type = case_when(
      is_t1w & !is_subsamp ~ "T1w_native",
      is_t1w & is_subsamp ~ "T1w_subsamp",
      is_mask & !is_subsamp ~ "mask_native",
      is_mask & is_subsamp ~ "mask_subsamp",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(file_type)) %>%
  select(sub_id, file_type, file) %>%
  pivot_wider(
    names_from = file_type,
    values_from = file,
    values_fn = first  # Take first if duplicates
  ) %>%
  filter(!gsub("^sub-", "", sub_id) %in% EXCLUDE_SUBJECTS) %>%
  arrange(sub_id)

message("Subjects processed: ", nrow(df_processed))
message("Columns: ", paste(names(df_processed), collapse = ", "))

if (nrow(df_processed) == 0) {
  stop("No subjects found after processing!")
}

# ---- helper ----
safe_pull <- function(files_row, col) {
  if (col %in% names(files_row)) {
    val <- as.character(files_row[[col]])
    if (length(val) == 1 && !is.na(val) && file.exists(val)) {
      return(val)
    }
  }
  return(NA_character_)
}

# ---- UI ----
ui <- fluidPage(
  titlePanel("Skull-Stripping QC"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "subject",
        "Choose subject:",
        choices = df_processed$sub_id,
        selected = if (nrow(df_processed) > 0) df_processed$sub_id[[1]] else NULL
      ),
      radioButtons(
        "resolution",
        "Resolution:",
        choices = c(
          "Native" = "native",
          "Subsampled (-subsamp2)" = "subsamp"
        ),
        selected = "subsamp"
      ),
      tags$hr(),
      uiOutput("file_status"),
      tags$hr(),
      tags$p("Red overlay = brain mask")
    ),
    
    mainPanel(
      tags$h4(textOutput("viewer_title")),
      papayaOutput("papayaView", height = "700px")
    )
  )
)

# ---- SERVER ----
server <- function(input, output, session) {
  
  output$viewer_title <- renderText({
    if (input$resolution == "native") {
      "T1w + Brain Mask (Native Resolution)"
    } else {
      "T1w + Brain Mask (-subsamp2)"
    }
  })
  
  output$file_status <- renderUI({
    req(input$subject)
    files_row <- df_processed %>% filter(sub_id == input$subject)
    
    has_native <- all(c("T1w_native", "mask_native") %in% names(files_row)) &&
      !is.na(files_row$T1w_native) && !is.na(files_row$mask_native)
    
    has_subsamp <- all(c("T1w_subsamp", "mask_subsamp") %in% names(files_row)) &&
      !is.na(files_row$T1w_subsamp) && !is.na(files_row$mask_subsamp)
    
    tagList(
      tags$div(
        style = "font-size: 0.9em;",
        tags$p(
          if (has_native) "✅ Native files available" else "❌ Native files missing"
        ),
        tags$p(
          if (has_subsamp) "✅ Subsampled files available" else "❌ Subsampled files missing"
        )
      )
    )
  })
  
  output$papayaView <- renderPapaya({
    req(input$subject, input$resolution)
    
    files_row <- df_processed %>% filter(sub_id == input$subject)
    
    t1w_col  <- paste0("T1w_", input$resolution)
    mask_col <- paste0("mask_", input$resolution)
    
    t1w_file  <- safe_pull(files_row, t1w_col)
    mask_file <- safe_pull(files_row, mask_col)
    
    imgs <- na.omit(c(t1w_file, mask_file))
    
    validate(
      need(
        length(imgs) > 0,
        paste0("No ", input$resolution, " resolution files found for ", input$subject, 
               ". Check that files exist in: ", data_dir, "/", gsub("^sub-", "", input$subject))
      )
    )
    
    opts <- list(
      papayaOptions(lut = "Grayscale")
    )
    
    if (length(imgs) == 2) {
      opts[[2]] <- papayaOptions(
        lut = "Red Overlay",
        alpha = 0.5,
        min = 0,
        max = 3
      )
    }
    
    papaya(
      imgs,
      sync_view = FALSE,
      hide_controls = TRUE,
      option = opts
    )
  })
}

shinyApp(ui, server)
