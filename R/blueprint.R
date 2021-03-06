#' Create a blueprint
#'
#' @param name The name of the blueprint
#' @param command The code to build the target dataset
#' @param description An optional description of the dataset to be used for 
#'   codebook generation
#' @param annotate If `TRUE`, during cleanup the metadata will "annotate"
#'   the dataset by adding variable attributes for each metadata field to 
#'   make metadata provenance easier and responsive to code changes.
#' @param metadata The associated variable metadata for this dataset
#' @param export_metadata Indicator to render new metadata file for new dataset
#' @param metadata_file_type The kind of metadata file. Currently only CSV.
#' @param metadata_directory Where the metadata file will be stored.
#' @param metadata_file_path Overrides the metadata file path generated by
#'   `metadata_directory`, `name`, and `metadata_file_type` if not NULL.
#' @param ... Any other parameters and settings for the blueprint
#' @param class A subclass of blueprint capability, for future work
#'
#' @return A blueprint object
#'
#' @details # Cleanup Tasks
#' blueprintr offers some post-check tasks that attempt to match datasets to the
#' metadata as much as possible. There are two default tasks that run:
#'   1. Reorders variables to match metadata order.
#'   1. Drops variables marked with `dropped == TRUE` if the `dropped` variable
#'      exists in the metadata.
#'
#' The remaining tasks have to be enabled by the user:
#'   * If `labelled = TRUE` in the `blueprint()` command, all columns will be
#'     converted to [labelled()][haven::labelled()] columns, provided that at
#'     least the `description` field is filled in. If the `coding` column is
#'     present in the metadata, then categorical levels as specified by a
#'     [coding()][rcoder::coding()] will be added to the column as well. In case
#'     the `description` field is used for detailed column descriptions, the
#'     `title` field can be added to the metadata to act as short titles for the
#'     columns.
#'
#' @export
blueprint <- function(
  name,
  command,
  description = NULL,
  metadata = NULL,
  annotate = FALSE,
  export_metadata = TRUE,
  metadata_file_type = c("csv"),
  metadata_directory = here::here("blueprints"),
  metadata_file_path = NULL,
  ...,
  class = character()
) {
  stopifnot(is.character(name))
  stopifnot(is.null(description) || is.character(description))

  captured_command <- capture_command(substitute(command))
  metadata_file_type <- match.arg(metadata_file_type)

  default_path <- file.path(
    metadata_directory,
    glue("{name}.{metadata_file_type}")
  )
  path <- metadata_file_path %||% default_path

  structure(
    list(
      name = name,
      command = captured_command,
      description = description,
      annotate = annotate,
      export_metadata = export_metadata,
      metadata_file_path = path,
      ...
    ),
    class = c(class, "blueprint")
  )
}

#' @export
print.blueprint <- function(x, ...) {
  cat_line("<blueprint: {ui_value(x$name)}>") # nocov start
  cat_line()

  if (!is.null(x$description)) {
    cat_line("Description: {x$description}")
  } else {
    cat_line("No description provided")
  }

  cat_line("Annotations: {if (isTRUE(x$annotate)) 'ENABLED' else 'DISABLED'}")

  cat_line("Metadata location: {ui_value(metadata_path(x))}")
  cat_line()

  if (!is.null(x$checks)) {
    cat_line("-- Dataset content checks --")
    print(x$checks)
    cat_line()
  }

  cat_line("-- Command --")
  cat_line("Drake command:")
  print(translate_macros(x$command))
  cat_line()
  cat_line("Raw command:")
  print(x$command)

  invisible(x) # nocov end
}

is_blueprint <- function(x) {
  inherits(x, "blueprint")
}

capture_command <- function(quoted_statement) {
  if (identical(quote(.), node_car(quoted_statement))) {
    return(eval(node_cdr(quoted_statement)[[1]]))
  }

  quoted_statement
}

blueprint_target_name <- function(x, ...) {
  UseMethod("blueprint_target_name")
}

#' @export
blueprint_target_name.default <- function(x, ...) {
  bp_err("Not defined")
}

#' @export
blueprint_target_name.character <- function(x, ...) {
  paste0(blueprint_final_name(x), "_initial")
}

#' @export
blueprint_target_name.blueprint <- function(x, ...) {
  blueprint_target_name(x$name)
}

blueprint_checks_name <- function(x, ...) {
  UseMethod("blueprint_checks_name")
}

#' @export
blueprint_checks_name.default <- function(x, ...) {
  bp_err("Not defined")
}

#' @export
blueprint_checks_name.character <- function(x, ...) {
  paste0(blueprint_final_name(x), "_checks")
}

#' @export
blueprint_checks_name.blueprint <- function(x, ...) {
  blueprint_checks_name(x$name)
}

blueprint_final_name <- function(x, ...) {
  UseMethod("blueprint_final_name")
}

#' @export
blueprint_final_name.default <- function(x, ...) {
  bp_err("Not defined")
}

#' @export
blueprint_final_name.character <- function(x, ...) {
  x
}

#' @export
blueprint_final_name.blueprint <- function(x, ...) {
  blueprint_final_name(x$name)
}

blueprint_reference_name <- function(x, ...) {
  UseMethod("blueprint_reference_name")
}

#' @export
blueprint_reference_name.default <- function(x, ...) {
  bp_err("Not defined")
}

#' @export
blueprint_reference_name.character <- function(x, ...) {
  paste0(blueprint_final_name(x), "_blueprint")
}

#' @export
blueprint_reference_name.blueprint <- function(x, ...) {
  blueprint_reference_name(x$name)
}

blueprint_codebook_name <- function(x, ...) {
  UseMethod("blueprint_codebook_name")
}

#' @export
blueprint_codebook_name.default <- function(x, ...) {
  bp_err("Not defined")
}

#' @export
blueprint_codebook_name.character <- function(x, ...) {
  paste0(blueprint_final_name(x), "_codebook")
}

#' @export
blueprint_codebook_name.blueprint <- function(x, ...) {
  blueprint_codebook_name(x$name)
}
