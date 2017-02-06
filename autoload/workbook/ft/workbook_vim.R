if (!exists("workbookComplete")) {
    workbookComplete <- function (base) {
        cs <- apropos(paste0("^", base))
        ls <- paste(cs, collapse = "\t")
        cat(ls)
        cat("\n")
    }
}


if (!exists("workbookHelp")) {
    workbookHelp <- function(name.string, ...) {
        help((name.string), try.all.packages = TRUE, ...)
    }
}


if (!exists("workbookKeyword")) {
    workbookKeyword <- function(name, name.string, ...) {
        if (name.string == '') {
            workbookHelp(name, ...)
        } else if (mode(name) == 'function') {
            workbookHelp(name.string, ...)
        } else {
            str(name)
        }
    }
}


