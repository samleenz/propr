#' @rdname propr
#' @section Methods (by generic):
#' \code{show:} Method to show \code{propr} object.
#'
#' @param object,x An object of class \code{propr}.
#' @importFrom methods show
#' @export
setMethod("show", "propr",
          function(object){

            cat("@counts summary:",
                nrow(object@counts), "subjects by", ncol(object@counts), "features\n")

            cat("@logratio summary:",
                nrow(object@logratio), "subjects by", ncol(object@logratio), "features\n")

            cat("@matrix summary:",
                nrow(object@matrix), "features by", ncol(object@matrix), "features\n")

            if(length(object@pairs) > 0 | nrow(object@matrix) == 0){

              cat("@pairs summary:", length(object@pairs), "feature pairs\n")

            }else{

              cat("@pairs summary: index with `[` method\n")
            }
          }
)

#' @rdname propr
#' @section Methods (by generic):
#' \code{subset:} Method to subset \code{propr} object.
#'
# #' @param x An object of class \code{propr}.
#' @param subset Subsets via \code{object@counts[subset, ]}.
#'  Use this argument to rearrange subject order.
#' @param select Subsets via \code{object@counts[, select]}.
#'  Use this argument to rearrange feature order.
#' @export
setMethod("subset", signature(x = "propr"),
          function(x, subset, select){

            if(missing(subset)) subset <- 1:nrow(x@counts)
            if(missing(select)) select <- 1:ncol(x@counts)

            if(is.character(select)){

              select <- which(colnames(x@counts) %in% select)
            }

            x@counts <- x@counts[subset, select, drop = FALSE]
            x@logratio <- x@logratio[subset, select, drop = FALSE]
            x@matrix <- x@matrix[select, select, drop = FALSE]

            if(length(x@pairs) > 0){

              cat("Alert: User must repopulate @pairs slot after `subset`.\n")
              x@pairs <- vector("numeric")
            }

            return(x)
          }
)

#' @rdname propr
#' @section Methods (by generic):
#' \code{[:} Method to subset \code{propr} object.
#'
# #' @param x An object of class \code{propr}.
#' @param i Operation used for the subset indexing. Select from
#'  "==", "=", ">", ">=", "<", "<=", "!=", or "all".
#' @param j Reference used for the subset indexing. Provide a numeric
#'  value to which to compare the proportionality metrics.
#' @aliases [,propr-method
#' @docType methods
#' @export
setMethod('[', signature(x = "propr", i = "ANY", j = "ANY"),
          function(x, i = "all", j){

            if(i == "all"){

              x@pairs <- indexPairs(x@matrix, "all")
              return(x)
            }

            if(!i %in% c("==", "=", ">", ">=", "<", "<=", "!=")){

              stop("Operator not recognized. Index using e.g., `prop[\">\", .95]`.")
            }

            if(missing(j) | !is.numeric(j) | length(j) != 1){

              stop("Reference not found. Index using e.g., `prop[\">\", .95]`.")
            }

            x@pairs <- indexPairs(x@matrix, i, j)

            if(length(x@pairs) == 0){

              stop("Method failed to index any pairs.")
            }

            return(x)
          }
)

#' @rdname propr
#' @section Methods (by generic):
#' \code{plot:} Method to plot \code{propr} object.
#'
# #' @param x An object of class \code{propr}.
#' @param y Missing. Ignore. Leftover from the generic method definition.
#' @param title A character string. A title for the \code{propr} plot.
#' @export
setMethod("plot", signature(x = "propr", y = "missing"),
          function(x, y, title = "Pairwise Proportionality"){

            if(!requireNamespace("ggplot2", quietly = TRUE)){
              stop("Uh oh! This plot method depends on ggplot2! ",
                   "Try running: install.packages('ggplot2')")
            }

            if(!requireNamespace("ggthemes", quietly = TRUE)){
              stop("Uh oh! This plot method depends on ggthemes! ",
                   "Try running: install.packages('ggthemes')")
            }

            if(length(x@pairs) == 0){

              cat("Alert: Generating plot using all feature pairs.\n")
              V <- indexPairs(x@matrix, "all")
              coord <- indexToCoord(V, nrow(x@matrix))

            }else{

              cat("Alert: Generating plot using indexed feature pairs.\n")
              V <- x@pairs
              coord <- indexToCoord(V, nrow(x@matrix))
            }

            # Melt *lr counts by feature pairs
            nsubj <- nrow(x@logratio)
            feat1 <- vector("numeric", length(V) * nsubj)
            feat2 <- vector("numeric", length(V) * nsubj)
            group <- vector("numeric", length(V) * nsubj)
            for(i in 1:length(V)){

              cat("Shaping pair", i, "...")
              i.order <- order(x@logratio[, coord$feat1[i]])
              feat1[((i-1)*nsubj + 1):((i-1)*nsubj + nsubj)] <- x@logratio[, coord$feat1[i]][i.order]
              feat2[((i-1)*nsubj + 1):((i-1)*nsubj + nsubj)] <- x@logratio[, coord$feat2[i]][i.order]
              group[((i-1)*nsubj + 1):((i-1)*nsubj + nsubj)] <- i
            }

            # Plot *lr-Y by *lr-X
            cat("\n")
            df <- data.frame("x.val" = feat1, "y.val" = feat2, "group" = group)
            p <- ggplot2::ggplot(data = df,
                                 ggplot2::aes_string(x = "x.val",
                                                     y = "y.val",
                                                     group = "group")) +
              ggplot2::geom_path(ggplot2::aes(colour = factor(df$group))) +
              ggplot2::labs(x = "Expression *LR mRNA[1]",
                            y = "Expression *LR mRNA[2]") +
              ggplot2::coord_equal(ratio = 1) +
              ggthemes::theme_base() +
              ggplot2::theme(legend.position = "none") +
              ggplot2::ggtitle(title)
            plot(p)

            return(p)
          }
)

#' @rdname propr
#' @section Methods (by generic):
#' \code{image:} Method to plot \code{propr} object.
#'
#' @param cexRow Numeric. Size of x-axis label.
#' @param cexCol Numeric. Size of y-axis label.
# #' @param object An object of class \code{propr}.
# #' @param title A character string. A title for the \code{propr} plot.
#' @export
setMethod("image", signature(x = "propr"),
          function(x, cexRow = 10, cexCol = 10, title = "*LR Transformed Image"){

            if(!requireNamespace("ggplot2", quietly = TRUE)){
              stop("Uh oh! This plot method depends on ggplot2! ",
                   "Try running: install.packages('ggplot2')")
            }

            if(length(x@pairs) == 0){

              cat("Alert: Generating plot using all feature pairs.\n")
              i.feat <- 1:nrow(x@matrix)

            }else{

              cat("Alert: Generating plot using indexed feature pairs.\n")
              V <- x@pairs
              coord <- indexToCoord(V, nrow(x@matrix))
              i.feat <- sort(union(coord[[1]], coord[[2]]))
            }

            # Prepare features for melting
            nfeat <- length(i.feat)
            feat <- vector("character", nfeat * nsubj)
            featnames <- colnames(x@logratio)[i.feat]
            if(is.null(featnames)){
              featnames <- paste("Feature", i.feat)
              cexCol <- 0
            }

            # Prepare subjects for melting
            nsubj <- nrow(x@logratio)
            subj <- vector("character", nfeat * nsubj)
            subjnames <- rownames(x@logratio)
            if(is.null(subjnames)){
              subjnames <- paste("Subject", 1:nsubj)
              cexRow <- 0
            }

            # Melt *lr counts by feature
            val <- vector("numeric", nfeat * nsubj)
            for(i in 1:nfeat){

              feat[((i-1)*nsubj + 1):((i-1)*nsubj + nsubj)] <- featnames[i]
              subj[((i-1)*nsubj + 1):((i-1)*nsubj + nsubj)] <- subjnames
              val[((i-1)*nsubj + 1):((i-1)*nsubj + nsubj)] <- x@logratio[, i]
            }

            # Plot *lr for each subject
            df <- data.frame("feature" = feat, "subject" = subj, "value" = val,
                             stringsAsFactors = FALSE)
            df$feature <- factor(df$feature, levels = unique(df$feature))
            df$subject <- factor(df$subject, levels = unique(df$subject))
            valMin <- floor(min(df$value))
            valMax <- ceiling(max(df$value))
            p <- ggplot2::ggplot(ggplot2::aes_string(x = "subject",
                                                     y = "feature"), data = df) +
              ggplot2::geom_tile(ggplot2::aes_string(fill = "value")) +
              ggplot2::scale_fill_gradient2(name = "Scaled *LR Expression",
                                            # low = "grey0", high = "grey70", mid = "grey35",
                                            low = "yellow", high = "red", mid = "orange",
                                            midpoint = 0,
                                            limit = c(valMin, valMax),
                                            breaks = seq(valMin, valMax)) +
              ggplot2::theme(axis.title.x = ggplot2::element_blank(),
                             axis.title.y = ggplot2::element_blank(),
                             axis.text.x = ggplot2::element_text(size = cexRow),
                             axis.text.y = ggplot2::element_text(size = cexCol),
                             panel.grid.major = ggplot2::element_blank(),
                             panel.border = ggplot2::element_blank(),
                             panel.background = ggplot2::element_blank(),
                             axis.ticks = ggplot2::element_blank(),
                             legend.position = "bottom") +
              ggplot2::ggtitle(title)
            plot(p)

            return(p)
          }
)

#' @rdname propr
#' @section Methods (by generic):
#' \code{plot:} Method to plot \code{propr} object.
#'
# #' @param object An object of class \code{propr}.
# #' @param title A character string. A title for the \code{propr} plot.
#' @param group A character or numeric vector. Supply feature groups for coloring.
#'  Feature groups expected in the order they appear in \code{@@counts}.
#' @importFrom stats as.dist as.dendrogram hclust order.dendrogram
#' @importFrom grDevices rainbow
#' @export
dendrogram <- function(object, title = "Proportional Clusters", group){

  if(!requireNamespace("dendextend", quietly = TRUE)){
    stop("Uh oh! This plot method depends on dendextend! ",
         "Try running: install.packages('dendextend')")
  }

  if(length(object@pairs) == 0){

    cat("Alert: Generating plot using all feature pairs.\n")
    i.feat <- 1:nrow(object@matrix)

  }else{

    cat("Alert: Generating plot using indexed feature pairs.\n")
    V <- object@pairs
    coord <- indexToCoord(V, nrow(object@matrix))
    i.feat <- sort(union(coord[[1]], coord[[2]]))
  }

  # Align features with groups in data.frame
  if(missing(group)) group <- 1
  featnames <- colnames(object@logratio)[i.feat]
  if(is.null(featnames)){
    featnames <- paste("Feature", i.feat)
  }
  colorKey <- data.frame("feature" = featnames,  "group" = group, "color" = NA,
                         stringsAsFactors = FALSE)

  # Assign 'n' colors based on 'n' groups
  grps <- unique(colorKey$group)
  colors <- rainbow(length(grps))
  for(i in 1:length(grps)){
    colorKey[colorKey$group == grps[i], "color"] <- colors[i]
  }

  # Build tree and color branches
  if(object@matrix[1, 1] == 0){

    # Convert phi into dist matrix
    dist <- as.dist(object@matrix[i.feat, i.feat])
    attr(dist, "Labels") <- featnames

  }else if(object@matrix[1, 1] == 1){

    # Convert rho into dist matrix
    # See reference: http://research.stowers-institute.org/
    #  mcm/efg/R/Visualization/cor-cluster/index.htm
    dist <- as.dist(1 - abs(object@matrix[i.feat, i.feat]))
    attr(dist, "Labels") <- featnames

  }else{

    stop("Matrix style not recognized.")
  }

  dend <- as.dendrogram(hclust(dist))
  dendextend::labels_colors(dend) <- colorKey$color[order.dendrogram(dend)]
  plot(dend, main = title)

  return(dend)
}