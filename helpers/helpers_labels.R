### Names #####################################################################

preprocessing_yesfilter_name <- "Filter übernehmen"
preprocessing_lastfilter_name <- "Letzten Filter löschen"
preprocessing_nofilter_name <- "Alle Filter löschen"
preprocessing_duplicate_name <- "Doppelte Zeilen entfernen"

preprocessing_ctype_name <- "Spaltentyp ändern"
preprocessing_cname_name <- "Spaltennamen ändern"
preprocessing_cpaste_name <- "Spalten vereinen"
preprocessing_cseparate_name <- "Spalten trennen"
preprocessing_cdelete_name <- "Spalten löschen"

preprocessing_cedit_name <- "Änderungen übernehmen"
preprocessing_cgsub_name <- "Zeichenfolgen ersetzen"

preprocessing_rcode_name <- "R-Code anwenden"
preprocessing_regex_name <- "Regulären Ausdruck anwenden"
preprocessing_aggreg_name <- "Funktion über Gruppen anwenden"
preprocessing_reverse_name <- "Änderungen zurücksetzen"

preprocessing_copy_name <- "Museum kopieren"
preprocessing_merge_name <- "Museen zusammenführen"
preprocessing_export_name <- "Museum exportieren"

### Text ######################################################################

preprocessing_ctype_text <- list(
  label = "Spaltentyp", 
  choices = c(
    "In „numeric“ umwandeln" = "numeric", 
    "In „character“ umwandeln" = "character",
    "In „factor“ umwandeln" = "factor"))

preprocessing_cpaste_text <- list(
  label = "Trennzeichen")

preprocessing_cseparate_text <- list(
  label = "Trennzeichen")

preprocessing_cdelete_text <- list(
  label = p("Anteil leere Zellen", 
    tooltipButton("preprocessing_cdelete_help", 
      fa_icon = icon("question-circle"))), 
  min = 0, max = 100, step = 1, value = 0)

preprocessing_cgsub_text <- list(
  label = "Zeichenfolgen", 
  placeholder = paste(
    "Bitte trennen Sie die Zeichenfolgen durch einen Zeilenumbruch.",
    "Die zu ersetzenden werden durch „ = “ von den ersetzenden Zeichen",
    "abgetrennt."))

preprocessing_rcode_text <- list(
  label = "R-Code", 
  placeholder = paste(
    "Bitte trennen Sie die Operationen durch einen Zeilenumbruch oder",
    "ein Semikolon. Das jeweils ausgewählte Museum kann über das Objekt",
    "„data“ angesprochen werden."))

preprocessing_regex_text <- list(
  label = "Regulärer Ausdruck")

preprocessing_aggreg_text <- list(
  label = "Funktion", 
  choices = c(
    "Werte summieren" = "sum",
    "Werte mitteln" = "mean",
    "Werte zählen" = "NROW"))

preprocessing_copy_text <- list(
  label = "Museumsname")

preprocessing_merge_text <- list(
  label = "Museumsname")

preprocessing_export_text <- list(
  label = "Format auswählen", 
  choices = c(
    "Als CSV exportieren" = "csv", 
    "Als RDS exportieren" = "rds"))
