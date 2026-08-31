# Shared data-wrangling and statistical helpers for figure notebooks.

subset_timepoint <- function(data, metadata, timepoint) {
  keep <- metadata$Timepoint == timepoint
  list(
    data = data[keep, , drop = FALSE],
    metadata = metadata[keep, , drop = FALSE]
  )
}

apply_detection_thresholds <- function(data, thresholds) {
  missing_features <- setdiff(names(thresholds), colnames(data))
  if (length(missing_features) > 0) {
    stop(
      "Threshold features missing from assay data: ",
      paste(missing_features, collapse = ", "),
      call. = FALSE
    )
  }

  detected <- data
  detected[names(thresholds)] <- Map(
    function(values, threshold) values >= threshold,
    data[names(thresholds)],
    thresholds
  )
  detected
}

make_sample_block <- function(data, metadata, sample_type, sex_column) {
  stopifnot(nrow(data) == nrow(metadata))

  data$PediID <- metadata$PediID
  data$sex <- metadata[[sex_column]]
  data$unique_groups <- metadata$unique_groups
  data$sample_type <- sample_type
  data
}

select_serology_features <- function(data, include, exclude = "IgA|IgM|FcaR") {
  selected <- data[, grepl(include, colnames(data)), drop = FALSE]
  selected[, !grepl(exclude, colnames(selected)), drop = FALSE]
}

make_feature_long <- function(sample_data, feature_data, group_levels) {
  analysis_data <- feature_data
  analysis_data$PediID <- sample_data$PediID
  analysis_data$sample_type <- factor(
    sample_data$sample_type,
    levels = group_levels
  )

  tidyr::pivot_longer(
    analysis_data,
    cols = colnames(feature_data),
    names_to = "feature",
    values_to = "value"
  )
}

kruskal_by_feature <- function(long_data, group_column = "sample_type") {
  split_data <- split(long_data, long_data$feature)
  tests <- lapply(split_data, function(feature_data) {
    formula <- stats::reformulate(group_column, response = "value")
    result <- rstatix::kruskal_test(feature_data, formula)
    data.frame(feature = feature_data$feature[1], p_value = result$p)
  })

  results <- do.call(rbind, tests)
  results$q_value <- stats::p.adjust(results$p_value, method = "fdr")
  rownames(results) <- NULL
  results
}

add_detection_status <- function(long_data, thresholds) {
  feature_threshold <- unname(thresholds[long_data$feature])
  if (anyNA(feature_threshold)) {
    missing <- unique(long_data$feature[is.na(feature_threshold)])
    stop("Missing detection threshold(s): ", paste(missing, collapse = ", "))
  }

  long_data$detected <- long_data$value >= feature_threshold
  long_data
}

summarize_detection <- function(long_data, group_column = "sample_type") {
  group_values <- long_data[[group_column]]
  totals <- stats::aggregate(
    long_data$detected,
    by = list(feature = long_data$feature, group = group_values),
    FUN = function(x) paste0(sum(x), "/", length(x))
  )
  names(totals)[3] <- "detected"

  tidyr::pivot_wider(totals, names_from = "group", values_from = "detected")
}

filter_detected_features <- function(
    data,
    detected_data,
    minimum_fraction = 0.30) {
  fractions <- colMeans(detected_data[colnames(data)], na.rm = TRUE)
  data[, fractions >= minimum_fraction, drop = FALSE]
}

format_feature_label <- function(feature) {
  label <- gsub("_", " ", feature)
  label <- sub("^IgG ", "Total IgG ", label)
  label <- gsub("FcgR2AR", "FcgR2A", label)
  gsub("FcgR3AV", "FcgR3A", label)
}
