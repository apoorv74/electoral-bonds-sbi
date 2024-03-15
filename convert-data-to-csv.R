library(tabulizer)
library(dplyr)
library(stringr)
library(glue)
library(readr)

pdf_path <- "eci-pdf/"
eci_files <- c("encashment","purchaser")
file_format <- ".pdf"
col_names <-
  list(
    "encashment" = c("dateOfEncashment", "politicalParty", "denomination"),
    "purchaser" = c("dateOfPurchase", "purchaserName", "denomination")
  )

file_details <- c()
for(f in 1:length(eci_files)){
  pdf_file <- glue::glue("{pdf_path}{eci_files[[f]]}{file_format}")
  total_pages <- get_n_pages(file = pdf_file)
  all_table <- tabulizer::extract_tables(file = pdf_file)
  records_per_page <- lapply(all_table, nrow) %>% unlist()
  tables_df <- as.data.frame(do.call(rbind, all_table))
  total_rows <- nrow(tables_df)

  # Remove the first row  
  tables_df <- tables_df[-1,]
  
  # Assign column names
  names(tables_df) <- col_names[[f]]
  
  # Convert denomination to numeric
  tables_df$denomination <- stringr::str_replace_all(tables_df$denomination,pattern = ",",replacement = "")
  tables_df$denomination <- as.numeric(tables_df$denomination)
  
  total_denomination <- sum(tables_df$denomination)
  file_details[[f]] <-
    list(
      "title" = pdf_file,
      "total_pages" = total_pages,
      "total_rows" = total_rows,
      "total_denomination" = total_denomination,
      "records_per_page" = records_per_page
    )
  
  #Write data to disk
  file_path <- glue::glue("data/{eci_files[f]}.csv")
  readr::write_csv(tables_df,file_path)
  
  print(glue::glue("Saved {total_rows} in {eci_files[f]} file"))
}

#Write metadata to disk
jsonlite::write_json(file_details,
                     "data/metadata.json",
                     auto_unbox = TRUE,
                     pretty = TRUE)
