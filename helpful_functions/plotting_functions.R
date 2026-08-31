# Plotting helpers shared by the longitudinal and multivariate analyses.

publication_theme <- function(
    title_size = 12,
    axis_title_size = 8,
    axis_text_size = 6) {
  ggplot2::theme_classic() +
    ggplot2::theme(
      legend.position = "none",
      plot.title = ggplot2::element_text(
        hjust = 0.55,
        face = "bold",
        size = title_size
      ),
      axis.text = ggplot2::element_text(size = axis_text_size, color = "black"),
      axis.title = ggplot2::element_text(size = axis_title_size, face = "bold"),
      axis.title.x = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(fill = "transparent"),
      panel.background = ggplot2::element_rect(fill = "transparent"),
      plot.background = ggplot2::element_rect(fill = "transparent", colour = NA)
    )
}

plot_longitudinal_feature <- function(
    long_data,
    feature,
    thresholds,
    colors,
    x_labels,
    y_positions = NULL) {
  feature_data <- long_data[long_data$feature == feature, , drop = FALSE]
  feature_data$plot_group <- factor(
    feature_data$sample_type,
    levels = names(x_labels),
    labels = unname(x_labels)
  )

  plot <- ggplot2::ggplot(
    feature_data,
    ggplot2::aes(.data$plot_group, .data$value)
  ) +
    ggplot2::geom_line(
      ggplot2::aes(group = .data$PediID),
      color = "gray",
      alpha = 0.5
    ) +
    ggplot2::geom_point(
      ggplot2::aes(fill = .data$plot_group),
      shape = 21,
      size = 2.5
    ) +
    ggplot2::geom_hline(
      yintercept = unname(thresholds[feature]),
      linetype = "dashed"
    ) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::labs(
      x = NULL,
      y = "log10 (MFI)",
      title = format_feature_label(feature)
    ) +
    publication_theme()

  test <- try(
    rstatix::dunn_test(
      feature_data,
      value ~ plot_group,
      p.adjust.method = "bonferroni"
    ),
    silent = TRUE
  )

  if (!inherits(test, "try-error")) {
    test <- rstatix::remove_ns(test)
    if (nrow(test) > 0) {
      test <- rstatix::add_xy_position(test, x = "plot_group")
      if (!is.null(y_positions)) {
        test$y.position <- y_positions[seq_len(nrow(test))]
      }
      plot <- plot + ggprism::add_pvalue(
        test,
        label = "p.adj.signif",
        xmin = "xmin",
        xmax = "xmax",
        tip.length = c(0, 0),
        label.size = 2.6
      )
    }
  }
  plot
}

make_plsda_feature_metadata <- function(features, colors) {
  metadata <- data.frame(name = features)
  metadata$label <- vapply(features, format_feature_label, character(1))
  metadata$feature_class <- ifelse(grepl("^Ig", features), "titer", "Fc")
  metadata$feature_class <- factor(metadata$feature_class)
  metadata$antigen <- factor(sub("^[^_]+_", "", features))

  colors$antigen <- grDevices::colorRampPalette(
    RColorBrewer::brewer.pal(8, "Dark2")
  )(nlevels(metadata$antigen))
  names(colors$antigen) <- levels(metadata$antigen)

  colors$feature_class <- grDevices::colorRampPalette(
    RColorBrewer::brewer.pal(3, "Set1")
  )(nlevels(metadata$feature_class))
  names(colors$feature_class) <- levels(metadata$feature_class)

  list(metadata = metadata, colors = colors)
}

make_vip_table <- function(model, x_matrix, y, minimum_vip = 1) {
  vip_values <- ropls::getVipVn(model)
  feature_names <- names(vip_values)
  if (is.null(feature_names)) {
    feature_names <- rownames(as.matrix(vip_values))
  }

  vip <- data.frame(
    VIP = as.numeric(vip_values),
    feature = feature_names
  )

  vip$enriched <- vapply(vip$feature, function(feature) {
    class_means <- tapply(x_matrix[, feature], y, mean)
    names(which.max(class_means))
  }, character(1))

  vip <- vip[vip$VIP > minimum_vip, , drop = FALSE]
  vip <- vip[order(vip$VIP, decreasing = TRUE), , drop = FALSE]
  vip$enriched <- factor(vip$enriched, levels = levels(y))
  vip$label <- factor(
    vapply(vip$feature, format_feature_label, character(1)),
    levels = vapply(vip$feature, format_feature_label, character(1))
  )
  vip
}
