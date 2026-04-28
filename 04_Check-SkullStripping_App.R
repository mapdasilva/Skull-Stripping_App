library(shiny)
library(tidyverse)
library(papayaWidget)

# ---- Outliers - EXCLUSION LIST ----
# Add subject IDs to exclude (WITHOUT "sub-" prefix)
EXCLUDE_SUBJECTS <- c("BSCMR075")

# ---- data directory ----
data_dir <- "data_for_skullstrip"

# ---- list relevant files recursively ----
files <- list.files(
  data_dir,
  pattern = "sub-.*(desc-(preproc_T1w|brain_mask)).*\\.(nii\\.gz)$",
  recursive = TRUE,
  full.names = TRUE
)

message("Found ", length(files), " skull-stripping files in ", data_dir)

# ---- build dataframe of files ----
df <- tibble(file = files) %>%
  mutate(
    filename = basename(file),
    sub_id = str_extract(filename, "sub-[A-Za-z0-9]+"),
    type = case_when(
      str_detect(filename, "desc-preproc_T1w") ~ "T1w_native",
      str_detect(filename, "desc-brain_mask")  ~ "mask_native",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(type)) %>%
  select(sub_id, type, file) %>%
  pivot_wider(names_from = type, values_from = file) %>%
  filter(!gsub("^sub-", "", sub_id) %in% EXCLUDE_SUBJECTS) %>%
  arrange(sub_id)

message("Subjects with skull-stripping data (after exclusions): ", nrow(df))

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
        choices = df$sub_id,
        selected = if (nrow(df) > 0) df$sub_id[[1]] else NULL
      ),
      tags$p("Overlay of native T1w and native brain mask for skull-stripping QC.")
    ),
    
    mainPanel(
      tags$h4("T1w + Brain Mask (Native Space)"),
      papayaOutput("papayaView1", height = "700px")
    )
  )
)

# ---- SERVER ----
server <- function(input, output, session) {
  
  output$papayaView1 <- renderPapaya({
    req(input$subject)
    
    files_row <- df %>% filter(sub_id == input$subject)
    
    t1w_file  <- safe_pull(files_row, "T1w_native")
    mask_file <- safe_pull(files_row, "mask_native")
    
    imgs <- na.omit(c(t1w_file, mask_file))
    
    validate(
      need(length(imgs) > 0, "No T1w or mask file found for this subject.")
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