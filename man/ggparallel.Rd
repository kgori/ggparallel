\name{ggparallel}
\alias{ggparallel}
\title{Variations of parallel coordinate plots}
\usage{
  ggparallel(vars = list(), data, weight = NULL,
    method = "angle", alpha = 0.5, width = 0.25, order = 1,
    asp = NULL, label = TRUE, angle = 90,
    text.offset = NULL, color = "white", ...)
}
\arguments{
  \item{vars}{list of variable names to be included in the
  plotting. order of the variables is preserved in the
  display}

  \item{data}{data frame}

  \item{weight}{weighting variable - use character string}

  \item{method}{plotting method to use - one of
  \code{angle}, \code{parset}, or \code{hammock}, for a
  hammock plot the aspect ratio needs to be fixed.}

  \item{alpha}{level of $\alpha$ blending for ribbons,
  value between 0 and 1, defaults to 0.5.}

  \item{width}{width of variables}

  \item{order}{flag variable with three levels -1, 0, 1 for
  levels in decreasing order, levels in increasing order
  and levels unchanged. This variable can be either a
  scalar or a vector}

  \item{label}{binary variable (vector), whether labels
  should be shown.}

  \item{angle}{numeric value in degrees, by which text for
  labelling is rotated. Ignored if label = FALSE}

  \item{text.offset}{(vector) of values for offset the
  labels}

  \item{asp}{aspect ratio of the plot - it will be set to a
  default of 1 in the case of hammock plots.}

  \item{color}{value used for color of the boxes.}

  \item{...}{passed on directly to all of the ggplot2
  commands}
}
\value{
  returns a ggplot2 object that can be plotted directly or
  used as base layer for additional modifications.
}
\description{
  Hammock plots and parallel sets allow visualization of
  pairwise relationships between categorical variables.
}
\details{
  Parallel sets have been suggested by Kosara et al (2006)
  as a visualization technique to incorporate categorical
  variables into a parallel coordinate plot (Wegman,
  Inselberg reference). However, perceptual problems with
  interpreting line widths, make this chart type a victim
  of wrong conclusions. The hammock display (Schonlau 2003)
  and the common angle plots are two approaches at fixing
  this problem: in Hammock plots the linewidth is adjusted
  by a factor countering the strength of the illusion, in
  the common angle plot all lines are adjusted to show the
  same angle - making line widths again comparable across
  ribbons.
}
\examples{
data(mtcars)
ggparallel(list("gear", "cyl"), data=mtcars)

## compare with method='parset'
ggparallel(list("gear", "cyl"), data=mtcars, method='parset')

## flip plot and rotate text
ggparallel(list("gear", "cyl"), data=mtcars, angle=0) + coord_flip()

## change colour scheme
ggparallel(list("gear", "cyl"), data=mtcars, angle=0) + coord_flip() +
  scale_fill_brewer(palette="Set1") +
  scale_colour_brewer(palette="Set1")

## example with more than two variables:
titanic <- as.data.frame(Titanic)
ggparallel(names(titanic)[c(1,4,2,1)], order=0, titanic, weight="Freq") +
  scale_fill_brewer(palette="Paired", guide="none") +
  scale_colour_brewer(palette="Paired", guide="none")

## hammock plot with same width lines
ggparallel(names(titanic)[c(1,4,2,3)], titanic, weight=1, asp=0.5, method="hammock", order=c(0,0)) +
opts( legend.position="none") +
scale_fill_brewer(palette="Paired") +
scale_colour_brewer(palette="Paired")

## hammock plot with line widths adjusted by frequency
ggparallel(names(titanic)[c(1,4,2,3)], titanic, weight="Freq", asp=0.5, method="hammock", order=c(0,0)) +
opts( legend.position="none")

## biological examples: genes and pathways
data(genes)
require(RColorBrewer)
genes$chrom <- factor(genes$chrom, levels=c(paste("chr", 1:22, sep=""), "chrX", "chrY"))
ggparallel(list("path", "chrom"), text.offset=c(0.03, 0,-0.03), data = genes,  width=0.1, order=c(1,0), angle=0, color="white",
   factorlevels =  c(sapply(unique(genes$chrom), as.character),
     unique(genes$path))) +
   scale_fill_manual(values = c(   brewer.pal("YlOrRd", n = 9), rep("grey80", 24)), guide="none") +
   scale_colour_manual(values = c(   brewer.pal("YlOrRd", n = 9), rep("grey80", 24)), guide="none") +
   coord_flip()
}
\references{
  Matthias Schonlau (2003) Visualizing Categorical Data
  Arising in the Health Sciences Using Hammock Plots. In
  Proceedings of the Section on Statistical Graphics of the
  American Statistical Association.
  \url{http://www.schonlau.net/publication/03jsm_hammockplot.pdf}

  Robert Kosara, Fabian Bendix, Helwig Hauser (2006)
  Parallel Sets: Interactive Exploration and Visual
  Analysis of Categorical Data, Transactions on
  Visualization and Computer Graphics (TVCG), vol. 12, no.
  4, pp. 558-568.
  \url{http://kosara.net/papers/2006/Kosara_TVCG_2006.pdf}
}
