if (interactive()) {
    a <- Sys.time()

    home <- function() {
        home <- Sys.getenv("USERPROFILE")
        if (home == "") {
            home <- Sys.getenv("HOME")
        }
        home <- normalizePath(home, winslash = "/")
    }

    set_options <- function() {
        options(
            help_type = "html",
            setWidthOnResize = TRUE,
            tibble.print_max = 2000,
            max.print = 2000,
            warnPartialMatchAttr = TRUE,
            warnPartialMatchDollar = TRUE,
            repos = c("CRAN" = "http://cran.r-project.org"),
            # LSP Settings: https://github.com/REditorSupport/languageserver#settings
            r.lsp.log_file = file.path(home(), "Rlsplog"), # default: NULL
            r.lsp.debug = TRUE, # default: FALSE
            Ncpus = parallel::detectCores(logical = FALSE)
        )
        # knitr::opts_knit$set(progress = FALSE)
    }

    configure_vscode_r_plugin <- function() {
        # Usually we would just call: `source(file.path(home(), ".vscode-R",
        # "init.R"))` here, but init.R is broken when sourced from WSL, as it
        # contains Windows paths, so we include its fixed content directly here.
        if (any(grepl("VSCODE", names(Sys.getenv())))) {
            path <- file.path(
                home(), ".vscode*", "extensions", "reditorsupport.r-*",
                "R", "session", "init.R"
            )
            path <- Sys.glob(path)
            if (!length(path) == 0) {
                path <- path[length(path)] # source newest version
                cat("Sourcing: ", path, "\n", sep = "")
                local(source(path, chdir = TRUE, local = TRUE))
                options(
                    vsc.use_httpgd = TRUE,
                    device = function(...) {
                        httpgd::hgd(silent = TRUE)
                        .vsc.browser(httpgd::hgd_url(history = FALSE), viewer = "Beside") # nolint
                    },
                    vsc.globalenv = TRUE,
                    vsc.plot = TRUE,
                    vsc.browser = TRUE,
                    vsc.viewer = TRUE,
                    vsc.page_viewer = TRUE,
                    vsc.view = TRUE,
                    vsc.helpPanel = TRUE,
                    vsc.str.max.level = 2,
                    vsc.show_object_size = TRUE
                )
                Sys.setenv(TERM_PROGRAM = "vscode")
            } else {
                cat("Missing: $HOME/.vscode*/extensions/reditorsupport.r-*/R/*/init.R")
            }
        }
    }

    import_packages <- function() {
        Sys.setenv(`_R_S3_METHOD_REGISTRATION_NOTE_OVERWRITES_` = "FALSE")
        pkgs <- c(
            # "devtools",
            # "usethis",
            # "testthat",
            # "rlang",
            # "toscutil",
            # "toscmask",
            # "dplyr",
            # "envnames",
            # "pryr",
            # "sloop",
            # "toscdata",
            NULL
        )
        installed <- unname(utils::installed.packages()[, 1])
        wanted <- pkgs[!(pkgs %in% installed)]
        if (length(wanted > 0)) {
            Sys.setenv(DEBIAN_FRONTEND = "noninteractive")
            cat("Installing packages:", paste(wanted, collapse = ", "), "\n")
            utils::install.packages(
                wanted,
                Ncpus = parallel::detectCores(logical = FALSE)
            )
        }
        if (length(pkgs) > 0) {
            cat("Loading Packages:")
            for (p in pkgs) {
                cat("", p)
                suppressMessages(suppressWarnings(library(p, character.only = TRUE)))
            }
            cat("\n")
        }
        Sys.setenv(`_R_S3_METHOD_REGISTRATION_NOTE_OVERWRITES_` = "TRUE")
    }

    print_sys_locale <- function() {
        x <- utils::capture.output(dput(l10n_info()))
        x <- paste(x, collapse = "")
        x <- gsub("\\s+", " ", x)
        x <- gsub("^list\\(", "", x)
        x <- gsub("\\)$", "", x)
        x <- gsub(" = ", "=", x)
        x <- gsub("`", "", x)
        x <- paste0("\n")
        cat("Locale:", x)
    }

    clean_up_global_env <- function() {
        rm(list = ls(envir = .GlobalEnv), envir = .GlobalEnv)
    }

    set_options()
    configure_vscode_r_plugin()
    import_packages()
    print_sys_locale()
    b <- Sys.time()
    cat(sprintf("Startup time: %s seconds\n", trimws(formatC(b - a, digits = 3))))
    clean_up_global_env()
}
