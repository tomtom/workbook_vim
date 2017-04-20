if (!exists("workbookPager")) {
    workbookPager <- function(files, header, title, delete.file) {
        lines <- title
        for (path in files) {
            lines <- c(lines, header, readLines(path))
        }
        if (delete.file) file.remove(files)
        # lines <- gsub("^", "# ", lines)
        text <- paste(lines, collapse = "\n")
        text <- gsub("_\010", "", text)
        cat(text)
    }
}


invisible({options(width = 10000, pager = workbookPager)})


if (!exists("workbookComplete")) {
    workbookComplete <- function (base) {
        cs <- apropos(paste0("^", base), ignore.case = FALSE)
        ls <- paste(cs, collapse = "\t")
        cat(ls)
        cat("\n")
    }
}


if (!exists("workbookHelp")) {
    workbookHelp <- function(name.string, ...) {
        help(name.string, try.all.packages = TRUE, ...)
    }
}


if (!exists("workbookKeyword")) {
    workbookKeyword <- function(name, name.string, ...) {
        if (name.string == '') {
            workbookHelp(as.character(substitute(name)), ...)
        } else if (mode(name) == 'function') {
            workbookHelp(name.string, ...)
        } else {
            str(name)
        }
    }
}


if (!exists("workbookCtags")) {
    ### Credits:
    ### Based on https://github.com/jalvesaq/nvimcom/blob/master/R/etags2ctags.R
    ### Jakson Alves de Aquino
    ### Sat, July 17, 2010
    ### Licence: GPL2+
    workbookCtags <- function (ctagsfile = "tags") {
        wd <- gsub("\\", "/", getwd(), fixed = TRUE)
        home <- gsub("\\", "/", Sys.getenv("HOME"), fixed = TRUE)
        uprofile <- gsub("\\", "/", Sys.getenv("USERPROFILE"), fixed = TRUE)
        if (wd == home || wd == uprofile) {
            return()
        }
        rfile <- textConnection("rtags_lines", "w")
        rtags(recursive = TRUE, ofile = rfile, append = TRUE)
        on.exit({close(rfile); rm("rtags_lines", envir = .GlobalEnv)})
        ## etags2ctags(elines = rtags_lines, ctagsfile = 'tags')
        elines <- strsplit(rtags_lines, "\n", fixed = TRUE)
        filelen <- length(elines)
        nfread <- sum(elines == "\x0c")
        nnames <- filelen - (2 * nfread)
        clines <- vector(mode = "character", length = nnames)
        i <- 1
        k <- 1
        while (i < filelen) {
            if(elines[i] == "\x0c"){
                i <- i + 1
                curfile <- sub(",.*", "", elines[i])
                i <- i + 1
                curflines <- readLines(curfile)
                while(elines[i] != "\x0c" && i <= filelen){
                    curname <- sub(".\x7f(.*)\x01.*", "\\1", elines[i])
                    curlnum <- as.numeric(sub(".*\x01(.*),.*", "\\1", elines[i]))
                    curaddr <- curflines[as.numeric(curlnum)]
                    curaddr <- gsub("\\\\", "\\\\\\\\", curaddr)
                    curaddr <- gsub("\t", "\\\\t", curaddr)
                    curaddr <- gsub("/", "\\\\/", curaddr)
                    curaddr <- paste("/^", curaddr, "$", sep = "")
                    clines[k] <- paste(curname, curfile, curaddr, sep = "\t")
                    i <- i + 1
                    k <- k + 1
                }
            } else {
                stop("Error while trying to interpret line ", i, " of '", etagsfile, "'.\n")
            }
        }
        curcollate <- Sys.getlocale(category = "LC_COLLATE")
        invisible(Sys.setlocale(category = "LC_COLLATE", locale = "C"))
        clines <- sort(clines)
        invisible(Sys.setlocale(category = "LC_COLLATE", locale = curcollate))
        writeLines(clines, ctagsfile)
    }
}


if (!exists("workbookServer")) {
    workbookJsonDecorate <- function (fn) {
        argnames <- names(formals(fn))
        function (req, res, err) {
            pnames <- names(req$params)
            args <- req$params[pnames[pnames %in% argnames]]
            rv <- do.call(fn, args)
            res$json(rv)
        }
    }
    workbookServer <- function (id) {
        library("jug")
        jug() %>%
        get(path = "/complete//(?<base>.*)", workbookJsonDecorate(workbookComplete)) %>%
        get(path = "/eval", workbookJsonDecorate(workbookComplete)) %>%
        serve_it()
    }
}


if (!exists("workbookRserveEval")) {
    workbook.rserve.connection <- NULL
    workbookRserveEval <- function (code) {
        if (is.na(match("Rserve", .packages(all.available = TRUE, lib.loc = .libPaths())))) {
            stop("Please install Rserve first!")
        }
        if (is.na(match("RSclient", .packages(all.available = TRUE, lib.loc = .libPaths())))) {
            stop("Please install RSclient first!")
        }
        library("RSclient")
        if (is.null(workbook.rserve.connection)) {
            workbook.rserve.connection <<- tryCatch(RS.connect(), error = function (e) {
                stop("Make sure an instance of RServe is running!", e)
            })
        }
        eval(substitute(RS.eval(workbook.rserve.connection, eval({code}, envir = .GlobalEnv)),
            list(code = parse(text = code))))
    }
    on.exit({
        if (!is.null(workbook.rserve.connection)) {
            on.exit(RS.server.shutdown(workbook.rserve.connection))
            on.exit(RS.close(workbook.rserve.connection))
        }
    }, add = TRUE)
}


# cat("workbook_vim.R loaded!\n")

