# File and object-loading helpers used throughout the analysis.

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, mustWork = TRUE)

  repeat {
    is_project_root <- file.exists(file.path(current, "README.md")) &&
      dir.exists(file.path(current, "Figure_1"))

    if (is_project_root) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not find the project root from: ", start, call. = FALSE)
    }
    current <- parent
  }
}

project_path <- function(...) {
  file.path(find_project_root(), ...)
}

input_path <- function(...) {
  input_dir <- Sys.getenv(
    "COVID_ANTIBODY_INPUT_DIR",
    unset = project_path("INPUT_VARIABLES")
  )
  file.path(input_dir, ...)
}

raw_data_path <- function(...) {
  raw_dir <- Sys.getenv(
    "COVID_ANTIBODY_RAW_DIR",
    unset = input_path("raw")
  )
  file.path(raw_dir, ...)
}

output_path <- function(figure, filename = NULL) {
  output_dir <- project_path("outputs", figure)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  if (is.null(filename)) {
    return(output_dir)
  }
  file.path(output_dir, filename)
}

assert_files_exist <- function(paths) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) {
    stop(
      "Required input file(s) not found:\n- ",
      paste(missing, collapse = "\n- "),
      "\n\nSet COVID_ANTIBODY_INPUT_DIR or COVID_ANTIBODY_RAW_DIR ",
      "to the directory containing the study data.",
      call. = FALSE
    )
  }
  invisible(paths)
}

load_rdata <- function(
    filename,
    expected_object = NULL,
    envir = parent.frame()) {
  path <- input_path(filename)
  assert_files_exist(path)
  loaded_objects <- load(path, envir = envir)

  if (!is.null(expected_object) && !expected_object %in% loaded_objects) {
    stop(
      "Expected object '", expected_object, "' was not found in ", filename,
      ". Objects present: ", paste(loaded_objects, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(loaded_objects)
}

save_rdata <- function(object_name, filename, envir = parent.frame()) {
  if (!exists(object_name, envir = envir, inherits = FALSE)) {
    stop("Object not found: ", object_name, call. = FALSE)
  }

  dir.create(input_path(), recursive = TRUE, showWarnings = FALSE)
  save(list = object_name, file = input_path(filename), envir = envir)
  invisible(input_path(filename))
}
