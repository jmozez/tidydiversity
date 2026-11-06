#' Venn diagram of species shared between groups
#'
#' Draws a Venn diagram of the species recorded in two to four groups of
#' sites, such as habitats or seasons. Each region shows the number of
#' species found in exactly that combination of groups, and optionally
#' their share of all species. Circles are used for two and three groups
#' and ellipses for four, so that every combination has its own region.
#'
#' @param data A data frame with one row per site (or sample) and species.
#' @param group The column defining the groups (two to four levels).
#' @param species The species column.
#' @param percent Also show each region's share of all species.
#' @param palette Colours for the groups: `"okabe_ito"`, `"grey"` or a
#'   vector of colours.
#' @param theme A ggplot2 theme, by default [theme_tidydiversity()].
#' @return A ggplot object. The counts are stored in its `regions`
#'   attribute.
#' @export
#' @examplesIf rlang::is_installed("ggplot2")
#' plot_venn(png_tree_ants, group = site)
#' plot_venn(wanang_caterpillars, group = site)
plot_venn <- function(data,
                      group,
                      species = species,
                      percent = TRUE,
                      palette = "okabe_ito",
                      theme = theme_tidydiversity(grid = "none")) {
  rlang::check_installed("ggplot2")
  g <- names(tidyselect::eval_select(enquo(group), data))
  s <- names(tidyselect::eval_select(enquo(species), data))
  if (length(g) != 1 || length(s) != 1) {
    cli::cli_abort("{.arg group} and {.arg species} must each be one column.")
  }
  keep <- !is.na(data[[g]]) & !is.na(data[[s]])
  grp <- data[[g]][keep]
  grp <- if (is.factor(grp)) droplevels(grp) else factor(grp, sort(unique(grp)))
  sets <- lapply(split(as.character(data[[s]][keep]), grp), unique)
  k <- length(sets)
  if (k < 2 || k > 4) {
    cli::cli_abort(c(
      "{.fn plot_venn} draws 2 to 4 groups.",
      "i" = "{.arg group} has {k} level{?s}."
    ))
  }
  shapes <- venn_shapes(k)
  outline <- venn_outlines(shapes, names(sets))
  regions <- venn_counts(sets)
  pos <- venn_label_pos(shapes)
  regions <- merge(regions, pos, by = "pattern")
  total <- length(unique(unlist(sets)))
  regions$label <- if (percent) {
    sprintf("%d\n(%.0f%%)", regions$n, 100 * regions$n / total)
  } else {
    as.character(regions$n)
  }
  set_lab <- venn_set_labels(shapes, names(sets), lengths(sets))

  p <- ggplot2::ggplot() +
    ggplot2::geom_polygon(
      ggplot2::aes(.data$x, .data$y, group = .data$set, fill = .data$set),
      data = outline, alpha = 0.25
    ) +
    ggplot2::geom_path(
      ggplot2::aes(.data$x, .data$y, group = .data$set, colour = .data$set),
      data = outline, linewidth = 0.7
    ) +
    ggplot2::geom_text(
      ggplot2::aes(.data$x, .data$y, label = .data$label),
      data = regions, size = 3.4, lineheight = 0.9
    ) +
    ggplot2::geom_text(
      ggplot2::aes(.data$x, .data$y,
        label = .data$label, colour = .data$set,
        hjust = .data$hjust
      ),
      data = set_lab, fontface = "bold", size = 3.8
    ) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0.3)) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = 0.1)) +
    ggplot2::labs(
      x = NULL, y = NULL, fill = g, colour = g,
      title = sprintf("%d species in %d groups", total, k)
    )
  p <- td_style(p, palette, theme) + td_blank_axes()
  attr(p, "regions") <- tibble::as_tibble(
    regions[order(regions$pattern), c("pattern", "groups", "n")]
  )
  p
}

# Species counts for every combination of sets: a species counts only in
# the region matching exactly the sets it occurs in.
venn_counts <- function(sets) {
  spp <- unique(unlist(sets))
  m <- vapply(sets, function(s) spp %in% s, logical(length(spp)))
  m <- matrix(m, ncol = length(sets))
  combos <- as.matrix(expand.grid(rep(list(c(FALSE, TRUE)), length(sets))))
  combos <- combos[rowSums(combos) > 0, , drop = FALSE]
  key <- function(x) paste(as.integer(x), collapse = "")
  sp_key <- apply(m, 1, key)
  pat <- apply(combos, 1, key)
  tibble::tibble(
    pattern = pat,
    groups = apply(combos, 1, function(x) paste(names(sets)[x], collapse = " & ")),
    n = vapply(pat, function(p) sum(sp_key == p), integer(1), USE.NAMES = FALSE)
  )
}

venn_shapes <- function(k) {
  switch(as.character(k),
    "2" = data.frame(cx = c(-0.55, 0.55), cy = 0, a = 1, b = 1, angle = 0),
    "3" = data.frame(
      cx = c(-0.55, 0.55, 0), cy = c(0.35, 0.35, -0.6), a = 1, b = 1,
      angle = 0
    ),
    "4" = data.frame(
      cx = c(-0.38, -0.12, 0.12, 0.38), cy = c(-0.2, 0.1, 0.1, -0.2),
      a = 1, b = 0.55, angle = c(-1, -1, 1, 1) * pi / 4
    )
  )
}

venn_inside <- function(shapes, x, y) {
  vapply(seq_len(nrow(shapes)), function(i) {
    s <- shapes[i, ]
    dx <- x - s$cx
    dy <- y - s$cy
    u <- dx * cos(s$angle) + dy * sin(s$angle)
    v <- -dx * sin(s$angle) + dy * cos(s$angle)
    (u / s$a)^2 + (v / s$b)^2 <= 1
  }, logical(length(x)))
}

venn_outlines <- function(shapes, sets) {
  t <- seq(0, 2 * pi, length.out = 200)
  out <- lapply(seq_len(nrow(shapes)), function(i) {
    s <- shapes[i, ]
    data.frame(
      set = sets[i],
      x = s$cx + s$a * cos(t) * cos(s$angle) - s$b * sin(t) * sin(s$angle),
      y = s$cy + s$a * cos(t) * sin(s$angle) + s$b * sin(t) * cos(s$angle)
    )
  })
  out <- do.call(rbind, out)
  out$set <- factor(out$set, levels = sets)
  out
}

# Label each region at the grid point furthest from its edge.
venn_label_pos <- function(shapes, n = 150) {
  r <- max(abs(c(shapes$cx, shapes$cy))) + max(shapes$a)
  xs <- seq(-r, r, length.out = n)
  grid <- expand.grid(x = xs, y = xs)
  ins <- matrix(venn_inside(shapes, grid$x, grid$y), ncol = nrow(shapes))
  pat <- apply(ins, 1, function(x) paste(as.integer(x), collapse = ""))
  pm <- matrix(pat, n, n)
  edge <- matrix(FALSE, n, n)
  edge[-1, ] <- edge[-1, ] | pm[-1, ] != pm[-n, ]
  edge[-n, ] <- edge[-n, ] | pm[-n, ] != pm[-1, ]
  edge[, -1] <- edge[, -1] | pm[, -1] != pm[, -n]
  edge[, -n] <- edge[, -n] | pm[, -n] != pm[, -1]
  edge <- as.vector(edge)
  pats <- setdiff(unique(pat), strrep("0", nrow(shapes)))
  out <- lapply(pats, function(p) {
    inr <- which(pat == p)
    bd <- which(pat == p & edge)
    if (!length(bd)) bd <- inr
    d <- vapply(inr, function(i) {
      min((grid$x[bd] - grid$x[i])^2 + (grid$y[bd] - grid$y[i])^2)
    }, numeric(1))
    j <- inr[which.max(d)]
    data.frame(pattern = p, x = grid$x[j], y = grid$y[j])
  })
  do.call(rbind, out)
}

venn_set_labels <- function(shapes, sets, sizes) {
  t <- seq(0, 2 * pi, length.out = 360)
  out <- lapply(seq_len(nrow(shapes)), function(i) {
    s <- shapes[i, ]
    x <- s$cx + s$a * cos(t) * cos(s$angle) - s$b * sin(t) * sin(s$angle)
    y <- s$cy + s$a * cos(t) * sin(s$angle) + s$b * sin(t) * cos(s$angle)
    lab <- sprintf("%s (%d)", sets[i], sizes[i])
    if (nrow(shapes) < 4) {
      up <- s$cy >= 0
      return(data.frame(
        set = sets[i], label = lab, x = s$cx,
        y = s$cy + if (up) s$b + 0.12 else -s$b - 0.12, hjust = 0.5
      ))
    }
    j <- which.max(x^2 + y^2)
    len <- sqrt(x[j]^2 + y[j]^2)
    data.frame(
      set = sets[i], label = lab,
      x = x[j] * (1 + 0.08 / len), y = y[j] * (1 + 0.08 / len),
      hjust = if (x[j] < -0.2) 1 else if (x[j] > 0.2) 0 else 0.5
    )
  })
  out <- do.call(rbind, out)
  out$set <- factor(out$set, levels = sets)
  out
}

td_blank_axes <- function() {
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank(),
    legend.position = "none"
  )
}

#' Plot a phylogeny with species abundances and phylogenetic diversity
#'
#' Draws a rectangular phylogram of a `phylo` tree with ggplot2. With
#' `data`, a column of dots per site beside the tips shows each species'
#' relative abundance at that site. With `highlight`, the branches leading
#' to the species found at one site are coloured: their summed length is
#' that site's Faith's phylogenetic diversity (PD; Faith 1992), the
#' quantity behind q = 0 phylogenetic Hill numbers (Chao et al. 2010).
#'
#' @param tree A rooted tree of class `phylo`, for example from
#'   [ape::read.tree()]. Without branch lengths every branch has length 1.
#' @param data Optional data frame of species records by site.
#' @param site,species,abundance Columns of `data`. Without `abundance`,
#'   each row counts as one record.
#' @param highlight Optional site whose branches to colour.
#' @param tip_labels Draw the tip labels (underscores become spaces).
#' @param theme A ggplot2 theme, by default [theme_tidydiversity()].
#' @return A ggplot object.
#' @references Faith, D. P. (1992). Conservation evaluation and
#'   phylogenetic diversity. *Biological Conservation*, 61, 1-10.
#'   \doi{10.1016/0006-3207(92)91201-3}
#'
#'   Chao, A., Chiu, C.-H. and Jost, L. (2010). Phylogenetic diversity
#'   measures based on Hill numbers. *Philosophical Transactions of the
#'   Royal Society B*, 365, 3599-3609. \doi{10.1098/rstb.2010.0272}
#' @export
#' @examplesIf rlang::is_installed(c("ape", "ggplot2"))
#' # A taxonomic tree (family / genus / species) for the Mt Wilhelm frogs
#' frogs <- png_frogs
#' frogs$genus <- sub(" .*", "", frogs$scientific_name)
#' frogs$tip <- gsub(" ", "_", frogs$scientific_name)
#' tax <- unique(as.data.frame(frogs[c("family", "genus", "tip")]))
#' tax[] <- lapply(tax, factor)
#' tree <- ape::compute.brlen(ape::as.phylo(~ family / genus / tip, data = tax))
#' plot_phylo(tree, frogs, species = tip, highlight = "MW0200")
plot_phylo <- function(tree,
                       data = NULL,
                       site = site,
                       species = species,
                       abundance = NULL,
                       highlight = NULL,
                       tip_labels = TRUE,
                       theme = theme_tidydiversity(grid = "none")) {
  rlang::check_installed("ggplot2")
  if (!inherits(tree, "phylo")) {
    cli::cli_abort("{.arg tree} must be a {.cls phylo} tree.")
  }
  lay <- phylo_layout(tree)
  nodes <- lay$nodes
  edges <- lay$edges
  n_tip <- length(tree$tip.label)
  x_max <- max(nodes$x)
  edges$hl <- FALSE
  subtitle <- NULL

  comm <- NULL
  if (!is.null(data)) {
    sc <- names(tidyselect::eval_select(enquo(site), data))
    spc <- names(tidyselect::eval_select(enquo(species), data))
    ab <- enquo(abundance)
    w <- if (rlang::quo_is_null(ab)) {
      rep(1, nrow(data))
    } else {
      data[[names(tidyselect::eval_select(ab, data))]]
    }
    comm <- stats::aggregate(
      list(n = w), list(site = as.character(data[[sc]]), tip = as.character(data[[spc]])),
      sum
    )
    comm <- comm[comm$n > 0 & comm$tip %in% tree$tip.label, ]
    comm$share <- comm$n / stats::ave(comm$n, comm$site, FUN = sum)
  }
  if (!is.null(highlight)) {
    if (is.null(comm) || !highlight %in% comm$site) {
      cli::cli_abort("{.arg highlight} must be a site in {.arg data}.")
    }
    present <- match(comm$tip[comm$site == highlight], tree$tip.label)
    edges$hl <- vapply(lay$tips_below[edges$child], function(t) any(t %in% present), logical(1))
    pd <- sum(edges$length[edges$hl])
    subtitle <- sprintf(
      "Highlighted: branches present at %s (PD = %s)", highlight, format(signif(pd, 3))
    )
  }

  hl_col <- c(`FALSE` = "grey45", `TRUE` = "#D55E00")
  p <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      ggplot2::aes(.data$x0, .data$y, xend = .data$x1, yend = .data$y, colour = .data$hl),
      data = edges, linewidth = 0.5, lineend = "square"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(.data$x, .data$y0, xend = .data$x, yend = .data$y1),
      data = lay$verticals, colour = "grey45", linewidth = 0.5, lineend = "square"
    ) +
    ggplot2::scale_colour_manual(values = hl_col, guide = "none")

  x_lab <- x_max * 1.02
  if (!is.null(comm)) {
    sites <- if (is.factor(data[[sc]])) levels(data[[sc]]) else sort(unique(data[[sc]]))
    sites <- intersect(as.character(sites), comm$site)
    step <- x_max * 0.06
    comm$x <- x_max * 1.05 + step * (match(comm$site, sites) - 1)
    comm$y <- nodes$y[match(comm$tip, tree$tip.label)]
    head <- data.frame(site = sites, x = x_max * 1.05 + step * (seq_along(sites) - 1))
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(.data$x, .data$y, size = .data$share),
        data = comm, colour = "#0072B2", alpha = 0.85
      ) +
      ggplot2::geom_text(
        ggplot2::aes(.data$x, n_tip + 1, label = .data$site),
        data = head, angle = 90, hjust = 0, vjust = 0.5, size = 3
      ) +
      ggplot2::scale_size_area(max_size = 4, name = "Relative\nabundance")
    x_lab <- max(head$x) + step * 0.8
  }
  if (tip_labels) {
    tips <- nodes[seq_len(n_tip), ]
    tips$label <- gsub("_", " ", tree$tip.label)
    p <- p + ggplot2::geom_text(
      ggplot2::aes(x_lab, .data$y, label = .data$label),
      data = tips, hjust = 0, size = 2.8, fontface = "italic"
    )
  }
  p <- p +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.45))) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(add = c(1, 3))) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = NULL, y = NULL, subtitle = subtitle)
  p <- td_style(p, NULL, theme) + td_blank_axes() +
    ggplot2::theme(legend.position = if (is.null(comm)) "none" else "right")
  p
}

# Node coordinates for a rectangular phylogram: x is the distance from the
# root, tips are spaced 1, 2, ... in preorder and internal nodes sit midway
# between their outermost children.
phylo_layout <- function(tree) {
  e <- tree$edge
  len <- tree$edge.length %||% rep(1, nrow(e))
  n_tip <- length(tree$tip.label)
  n_node <- n_tip + tree$Nnode
  root <- setdiff(e[, 1], e[, 2])[1]
  x <- numeric(n_node)
  pre <- integer(0)
  stack <- root
  while (length(stack)) {
    v <- stack[1]
    stack <- stack[-1]
    pre <- c(pre, v)
    ch <- which(e[, 1] == v)
    x[e[ch, 2]] <- x[v] + len[ch]
    stack <- c(e[ch, 2], stack)
  }
  y <- numeric(n_node)
  tip_order <- pre[pre <= n_tip]
  y[tip_order] <- seq_along(tip_order)
  below <- vector("list", n_node)
  for (v in rev(pre)) {
    ch <- e[e[, 1] == v, 2]
    if (!length(ch)) {
      below[[v]] <- v
    } else {
      y[v] <- mean(range(y[ch]))
      below[[v]] <- unlist(below[ch])
    }
  }
  internal <- unique(e[, 1])
  list(
    nodes = data.frame(node = seq_len(n_node), x = x, y = y),
    edges = data.frame(
      parent = e[, 1], child = e[, 2], length = len,
      x0 = x[e[, 1]], x1 = x[e[, 2]], y = y[e[, 2]]
    ),
    verticals = data.frame(
      x = x[internal],
      y0 = vapply(internal, function(v) min(y[e[e[, 1] == v, 2]]), numeric(1)),
      y1 = vapply(internal, function(v) max(y[e[e[, 1] == v, 2]]), numeric(1))
    ),
    tips_below = below
  )
}

#' Plot functional trait space
#'
#' Places species in a two-dimensional functional trait space, the first
#' two axes of a principal coordinates analysis (PCoA) of their trait
#' dissimilarities, as is usual for multidimensional functional diversity
#' indices (Villeger et al. 2008). With `data`, each group of sites gets
#' the convex hull of the species it holds, whose area is the
#' two-dimensional functional richness, and its community-weighted mean
#' position (CWM).
#'
#' @param traits A data frame with a species column and trait columns.
#' @param data Optional data frame of species records by group.
#' @param species The species column of `traits` and `data`.
#' @param group Column of `data` defining the groups to compare, such as
#'   habitats.
#' @param abundance Optional abundance column of `data`, used for the CWM.
#' @param distance Optional species dissimilarities (a `dist` with species
#'   labels). By default Gower distances from [trait_dist()].
#' @param labels Label the species.
#' @param palette Colours for the groups: `"okabe_ito"`, `"grey"` or a
#'   vector of colours.
#' @param theme A ggplot2 theme, by default [theme_tidydiversity()].
#' @return A ggplot object.
#' @references Villeger, S., Mason, N. W. H. and Mouillot, D. (2008). New
#'   multidimensional functional diversity indices for a multifaceted
#'   framework in functional ecology. *Ecology*, 89, 2290-2301.
#'   \doi{10.1890/07-1206.1}
#' @export
#' @examplesIf rlang::is_installed(c("ade4", "FD", "ggplot2"))
#' aravo <- data_aravo()
#' plot_trait_space(aravo$traits, aravo$community, group = ZoogD, abundance = cover)
plot_trait_space <- function(traits,
                             data = NULL,
                             species = species,
                             group = NULL,
                             abundance = NULL,
                             distance = NULL,
                             labels = FALSE,
                             palette = "okabe_ito",
                             theme = theme_tidydiversity(grid = "none")) {
  rlang::check_installed("ggplot2")
  if (is.null(distance)) distance <- trait_dist(traits, species = {{ species }})
  lab <- attr(distance, "Labels")
  if (is.null(lab)) {
    cli::cli_abort("{.arg distance} must carry species labels.")
  }
  pc <- stats::cmdscale(distance, k = 2, eig = TRUE)
  pos <- pc$eig[pc$eig > 0]
  expl <- 100 * pc$eig[1:2] / sum(pos)
  sp <- data.frame(species = lab, x = pc$points[, 1], y = pc$points[, 2])

  p <- ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey70", linewidth = 0.3) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey70", linewidth = 0.3)
  if (!is.null(data)) {
    spc <- names(tidyselect::eval_select(enquo(species), data))
    gq <- enquo(group)
    if (rlang::quo_is_null(gq)) cli::cli_abort("{.arg group} is needed with {.arg data}.")
    gc <- names(tidyselect::eval_select(gq, data))
    ab <- enquo(abundance)
    w <- if (rlang::quo_is_null(ab)) {
      rep(1, nrow(data))
    } else {
      data[[names(tidyselect::eval_select(ab, data))]]
    }
    comm <- stats::aggregate(
      list(w = w),
      list(group = data[[gc]], species = as.character(data[[spc]])), sum
    )
    comm <- comm[comm$w > 0, ]
    comm <- merge(comm, sp, by = "species")
    hulls <- do.call(rbind, lapply(split(comm, comm$group, drop = TRUE), function(d) {
      if (nrow(d) < 3) {
        return(NULL)
      }
      d[grDevices::chull(d$x, d$y), ]
    }))
    cwm <- do.call(rbind, lapply(split(comm, comm$group, drop = TRUE), function(d) {
      data.frame(
        group = d$group[1], x = stats::weighted.mean(d$x, d$w),
        y = stats::weighted.mean(d$y, d$w)
      )
    }))
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(.data$x, .data$y),
        data = sp, colour = "grey60", size = 1.6
      ) +
      ggplot2::geom_polygon(
        ggplot2::aes(.data$x, .data$y, fill = .data$group, colour = .data$group),
        data = hulls, alpha = 0.12, linewidth = 0.6
      ) +
      ggplot2::geom_point(
        ggplot2::aes(.data$x, .data$y, fill = .data$group),
        data = cwm, shape = 23, size = 4, colour = "black"
      ) +
      ggplot2::labs(
        fill = gc, colour = gc,
        caption = "Hulls: species in each group. Diamonds: community-weighted means."
      )
  } else {
    p <- p + ggplot2::geom_point(
      ggplot2::aes(.data$x, .data$y),
      data = sp, colour = "#0072B2", size = 2
    )
  }
  if (labels) {
    p <- p + ggplot2::geom_text(
      ggplot2::aes(.data$x, .data$y, label = .data$species),
      data = sp, size = 2.6, vjust = -0.8, check_overlap = TRUE
    )
  }
  p <- p + ggplot2::coord_equal() +
    ggplot2::labs(
      x = sprintf("PCoA 1 (%.1f%%)", expl[1]),
      y = sprintf("PCoA 2 (%.1f%%)", expl[2])
    )
  td_style(p, palette, theme)
}
