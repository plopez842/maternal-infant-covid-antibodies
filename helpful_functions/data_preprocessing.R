# Functions for cleaning assay values and deriving vaccination metadata.

excel_dates <- function(x) {
  as.character(lubridate::excel_numeric_to_date(
    as.numeric(as.character(x)),
    date_system = "modern"
  ))
}

background_correct <- function(assay_data, pbs_mean) {
  corrected <- sweep(as.data.frame(assay_data), 2, pbs_mean, FUN = "-")
  corrected[] <- lapply(corrected, function(x) log10(pmax(as.numeric(x), 1)))
  corrected
}

weeks_days_to_days <- function(x) {
  match <- regexec("^([0-9]+)w([0-9]+)d$", x)
  pieces <- regmatches(x, match)

  vapply(pieces, function(piece) {
    if (length(piece) != 3) {
      return(NA_real_)
    }
    as.numeric(piece[2]) * 7 + as.numeric(piece[3])
  }, numeric(1))
}

gestational_age_at_event <- function(reference_date, reference_ga, event_date) {
  days_before_reference <- as.numeric(difftime(
    as.Date(reference_date),
    as.Date(event_date),
    units = "days"
  ))
  reference_ga - days_before_reference
}

classify_covid_vaccination <- function(event_ga, delivery_ga) {
  dplyr::case_when(
    is.na(event_ga) ~ "No_Vax2",
    event_ga < 0 ~ "Pre-preg",
    event_ga > delivery_ga ~ "Post-preg",
    event_ga < 20 * 7 ~ "Conc_20w",
    event_ga < 28 * 7 ~ "20w_28w",
    TRUE ~ "28w_Birth"
  )
}

classify_pregnancy_vaccination <- function(event_ga, delivery_ga) {
  dplyr::case_when(
    is.na(event_ga) ~ "No_Vax2",
    event_ga < 0 ~ "Before Pregnancy",
    event_ga > delivery_ga ~ "Post-preg",
    event_ga < 20 * 7 ~ "Before 20 weeks",
    event_ga < 28 * 7 ~ "Between 20 to 28 weeks",
    TRUE ~ "After 28 weeks"
  )
}

collapse_outside_pregnancy <- function(x) {
  dplyr::if_else(x %in% c("Post-preg", "No_Vax2"), "Outside Pregnancy", x)
}

label_covid_vaccine_groups <- function(vax1_group, vax2_group) {
  group_levels <- c(
    "Conc_20w\nConc_20w",
    "Conc_20w\n20w_28w",
    "20w_28w\n20w_28w",
    "20w_28w\n28w_Birth",
    "28w_Birth\n28w_Birth"
  )

  factor(
    paste(vax1_group, vax2_group, sep = "\n"),
    levels = group_levels,
    labels = paste("Group", seq_along(group_levels))
  )
}
