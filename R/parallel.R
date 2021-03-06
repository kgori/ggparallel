#' Variations of parallel coordinate plots
#' 
#' \code{\link{ggparallel}} implements and combines different types of parallel coordinate plots for 
#' categorical data:
#' hammock plots,  parallel sets plots, common angle plots, and common angle plots with a hammock-like adjustment for line widths. 
#' 
#' Parallel sets have been suggested by Kosara et al (2006) as a visualization technique to incorporate categorical variables into 
#' a parallel coordinate plot (Wegman, Inselberg reference). However, perceptual problems with interpreting line widths,  make this chart type a victim of wrong conclusions.
#' The  hammock display (Schonlau 2003) and the common angle plots are two approaches at fixing this problem: in Hammock plots the linewidth is adjusted by a factor countering
#' the strength of the illusion, in the common angle plot all lines are adjusted to show the same angle - making line widths again comparable across ribbons. Additionally, we can also adjust ribbons
#' in the common angle display for the angle, to make them appear having the same width (or height) across the display. We refer to this method as \code{adj.angle}. 
#' 
#' @param vars list of variable names to be included in the plotting. order of the variables is preserved in the display
#' @param data data frame 
#' @param weight weighting variable - use character string
#' @param method plotting method to use - one of \code{angle}, \code{adj.angle}, \code{parset},  or \code{hammock}, for a hammock plot the aspect ratio needs to be fixed.
#' @param alpha level of alpha blending for the fill color in ribbons, value has to be between 0 and 1, defaults to 0.5.
#' @param width width of variables 
#' @param order flag variable with three levels -1, 0, 1 for levels in decreasing order, levels in increasing order and levels unchanged. This variable can be either a scalar or a vector
#' @param ratio  used for methods with angle adjustments (method = \code{'hammock', 'adj.angle'}): specifies the height (width for horizontal displays) of the widest line as ratio of the overall display height (width for horizontal displays).
#' @param label binary variable (vector), whether labels should be shown.
#' @param text.angle numeric value in degrees, by which text for labelling is rotated. Ignored if label = FALSE
#' @param text.offset (vector) of values for offset the labels
#' @param asp aspect ratio of the plot - it will be set to a default of 1 in the case of hammock plots.
#' @param color value used for color of the boxes.
#' @param ... passed on directly to all of the ggplot2 commands
#' @return returns a  ggplot2 object that can be plotted directly or used as base layer for additional modifications.
#' @export
#' @references
#' Matthias Schonlau (2003) Visualizing Categorical Data Arising in the Health Sciences
#' Using Hammock Plots. In Proceedings of the Section on Statistical Graphics of the 
#' American Statistical Association. \url{http://www.schonlau.net/publication/03jsm_hammockplot.pdf}
#' 
#' Robert Kosara, Fabian Bendix, Helwig Hauser (2006) 
#' Parallel Sets: Interactive Exploration and Visual Analysis of Categorical Data, 
#' Transactions on Visualization and Computer Graphics (TVCG), vol. 12, no. 4, pp. 558-568. \url{http://kosara.net/papers/2006/Kosara_TVCG_2006.pdf}
#' 
#' @examples
#' data(mtcars)
#' ggparallel(list("gear", "cyl"), data=mtcars)
#' ggparallel(list("gear", "cyl"), data=mtcars, method="hammock")
#' 
#' ## combination of common angle plot and hammock adjustment:
#' ggparallel(list("gear", "cyl"), data=mtcars, method="adj.angle")
#' 
#' ## compare with method='parset'
#' ggparallel(list("gear", "cyl"), data=mtcars, method='parset')
#' 
#' ## flip plot and rotate text
#' ggparallel(list("gear", "cyl"), data=mtcars, text.angle=0) + coord_flip()
#' 
#' ## change colour scheme
#' ggparallel(list("gear", "cyl"), data=mtcars, text.angle=0) + coord_flip() + 
#'   scale_fill_brewer(palette="Set1") + 
#'   scale_colour_brewer(palette="Set1")
#'   
#' ## example with more than two variables:
#' titanic <- as.data.frame(Titanic)
#' ggparallel(names(titanic)[c(1,4,2,1)], order=0, titanic, weight="Freq") + 
#'   scale_fill_brewer(palette="Paired", guide="none") + 
#'   scale_colour_brewer(palette="Paired", guide="none")
#'   
#' ## hammock plot with same width lines
#' ggparallel(names(titanic)[c(1,4,2,3)], titanic, weight=1, asp=0.5, method="hammock", ratio=0.2, order=c(0,0)) +
#' theme( legend.position="none") + 
#' scale_fill_brewer(palette="Paired") + 
#' scale_colour_brewer(palette="Paired")
#' 
#' ## hammock plot with line widths adjusted by frequency
#' ggparallel(names(titanic)[c(1,4,2,3)], titanic, weight="Freq", asp=0.5, method="hammock", order=c(0,0)) + 
#' theme( legend.position="none")
#' 
#' \dontrun{
#' ## biological examples: genes and pathways
#' data(genes)
#' genes$chrom <- factor(genes$chrom, levels=c(paste("chr", 1:22, sep=""), "chrX", "chrY"))
#' ggparallel(list("path", "chrom"), text.offset=c(0.03, 0,-0.03), data = genes,  width=0.1, order=c(1,0), text.angle=0, color="white",
#'    factorlevels =  c(sapply(unique(genes$chrom), as.character), 
#'      unique(genes$path))) + 
#'    scale_fill_manual(values = c(   brewer.pal("YlOrRd", n = 9), rep("grey80", 24)), guide="none") + 
#'    scale_colour_manual(values = c(   brewer.pal("YlOrRd", n = 9), rep("grey80", 24)), guide="none") +
#'    coord_flip()
#' }


ggparallel <- function(vars=list(), data, weight=NULL, method="angle", 
      alpha=0.5, width=0.25, order = 1,  ratio=NULL, asp=NULL, label=TRUE, 
      text.angle=90, text.offset=NULL, text.colour=NULL, text.size=4, 
      text.shadow=TRUE, text.shadow.colour=NULL, text.shadow.size=4, 
      text.shadow.x.offset=0.01, text.shadow.y.offset=0.01, ...) {
  ### Package requirements
  require(ggplot2)
  require(plyr)
  require(reshape2)
  ### error checking
  vars <- unlist(vars)
  k = length(vars)
  if (k < 2) message("Error: ggparallel needs at least two variables. Use vars=list('X', 'Y')")
  
  ## if user doesn't specify the weight, assign value of 1. 
  data$weight <- weight
  if (is.null(weight)) data$weight <- 1
  if (is.character(weight)) data$weight <- data[,weight]
  
  ## if ordering is selected, organize x and y axis by weight
  ## make order a vector of length length(vars)
  order <- rep(order, length=length(vars))
  for (i in 1:length(vars)){
  if (! is.factor(data[,vars[i]])) 
      data[,vars[i]] <- factor(data[,vars[i]])

    if (order[i] != 0)
      data[,vars[i]] <- reorder(data[,vars[i]], data$weight, 
                             function(x) if (order[i] > 0) sum(x)
                                   else -sum(x)
                             )
  }
  
  llist <- NULL
  for (i in unique(vars)) {   
    levels(data[,i]) <- paste(i, levels(data[,i]), sep=":")
    llist <- c(llist, levels(data[,i]))
  }
  if ((method=="hammock"))# | (method=="adj.angle"))
    if (is.null(asp)) asp <- 1
    
  ## helper function
  getRibbons <- function(xid,yid) {    
    ## get the names of the x and y variables
    x <- vars[xid]
    y <- vars[yid]
    
    xname <- x
    yname <- y
 
    ## introduce new variables as fail-safe, if local binding fails:
    variable <- NULL
    value <- NULL
    Freq <- NULL
    Nodeset <- NULL
    tangens <- NULL
    dx2 <- NULL
    midx <- NULL
    midy <- NULL
    ypos <- NULL
    varn <- NULL
    ymax <- NULL
    ymin <- NULL
    ymid <- NULL
    
    ## create the data table, x, y, and weight
    dfxy <- as.data.frame(xtabs(data$weight~data[,x] + data[,y]))
    dfxy <- subset(dfxy, Freq > 0)
     
    names(dfxy)[1:2] <- c(xname, yname)
    
    ## get the ordering for data according to x-axis categories
    idx <- order(dfxy[,x], dfxy[,y], decreasing = FALSE)
    
    ## find the position of X-axis connector
    dfxy$X[idx] <- cumsum(dfxy$Freq[idx])    
    
    ## get the ordering for data according to y-axis categories
    idx <- order(dfxy[,y], dfxy[,x], decreasing = FALSE)

    ## find the position of the Y-axis connector
    dfxy$Y[idx] <- cumsum(dfxy$Freq[idx])
    
    ## assign row number as id
    dfxy$id <- 1:nrow(dfxy)    

    dfm <- melt(dfxy, measure.var=c("X", "Y"))
    levels(dfm$variable) <- c(x,y)    
    
    dfxy$XX <- dfxy[,xname]
    dfxy$YY <- dfxy[,yname]
    
    dfm$Nodeset <- dfm[,xname]        
    dfm$Nodeset <- factor(dfm$Nodeset, levels=llist)

    dfm$offset <- c(width/2,-width/2)[as.numeric(dfm$variable)]
    dfm$xid <- xid - 1
    dfm$yid <- yid
    
    
    if (method=="parset") {
      r <- geom_ribbon(aes(x=as.numeric(variable)+offset+xid,
                           ymin=value -Freq, 
                           ymax= value, group=id, 
                      fill=Nodeset),  alpha=alpha, data=dfm)
    }
    if (method == "angle") {     
      dfm$x <- with(dfm, as.numeric(variable)+offset+xid)
      dfm<- ddply(dfm, .(id), transform, 
                  dx=max(x)-min(x),
                  dy=max(value) -min(value)
      )
      dfm$tangens = dfm$dy/dfm$dx
      maxslope <- 1.3*max(dfm$tangens) # add 15% of offset on each end of each variable
      dfm$newdx <- with(dfm, dy/maxslope)
      
      dfm2 <- dfm
      dfm2$offset <- with(dfm, (abs(offset) + (dx-newdx)/2) * sign(offset))
      dfm2$x <- with(dfm2, as.numeric(variable)+offset+xid)
      dfm3 <- ddply(dfm2, names(dfm2)[2], transform, 
                    dx2 = max(x[which(tangens==max(tangens))])
      )
      dfm3 <- ddply(dfm3, .(id), transform, shiftx = max(x)-dx2)
      dfm3$x <- dfm3$x - dfm3$shiftx
      dfm <- rbind(dfm, dfm3[,-(16:17)])
      r <- geom_ribbon(aes(x=x,ymin=value -Freq, ymax= value, group=id, 
                            fill=Nodeset), alpha=alpha, data=dfm)
    }
    if (method == "adj.angle") {     
      dfm$x <- with(dfm, as.numeric(variable)+offset+xid)
      dfm<- ddply(dfm, .(id), transform, 
                  dx=max(x)-min(x),
                  dy=max(value) -min(value)
      )
      dfm$tangens = dfm$dy/dfm$dx
      maxslope <- 1.3*max(dfm$tangens) # add 15% of offset on each end of each variable
      dfm$newdx <- with(dfm, dy/maxslope)
      
      dfm2 <- dfm
      dfm2$offset <- with(dfm, (abs(offset) + (dx-newdx)/2) * sign(offset))
      dfm2$x <- with(dfm2, as.numeric(variable)+offset+xid)
      dfm3 <- ddply(dfm2, names(dfm2)[2], transform, 
                    dx2 = max(x[which(tangens==max(tangens))])
      )
      dfm3 <- ddply(dfm3, .(id), transform, shiftx = max(x)-dx2)
      dfm3$x <- dfm3$x #- dfm3$shiftx
      dfm <- rbind(dfm, dfm3[,-(16:17)])
      dfm <- transform(dfm, ymin=value-Freq, ymax=value)
      dfm <- transform(dfm, ymid=(ymax+ymin)/2)
#      plot.asp <- length(vars)/(1.1*sum(data$weight))*asp
#      qplot(x, ymid, data=dfm, geom=c("line"), alpha=I(0.5), group=id, colour=factor(gear), size=Freq)+scale_size(range=4.2*c(min(dfm$Freq),max(dfm$Freq))) + scale_colour_discrete() + theme(legend.position="none") + ylim(c(0, 1.05*sum(data$weight)))
#browser()
      r <- list(geom_line(aes(x=x,y=ymid, group=id, colour=Nodeset, size=Freq), alpha=alpha, data=dfm),
        scale_size(guide="none", range=ratio*max(dfm$Freq)*c(min(dfm$Freq),max(dfm$Freq)))) #+ scale_colour_discrete()       
    }
    if (method=="hammock") {
      maxwidth = ratio/2*sum(data$weight)
      xtab <- ddply(dfxy, xname, summarise, value=sum(Freq))
      xtab$midx <- with(xtab, cumsum(value)- value/2)
      dfm <- merge(dfm, xtab[,c(xname, "midx")], by=xname)
      ytab <- ddply(dfxy, yname, summarise, value=sum(Freq))
      ytab$midy <- with(ytab, cumsum(value)- value/2)
      dfm <- merge(dfm, ytab[,c(yname, "midy")], by=yname)
      plot.asp <- length(vars)/(1.1*sum(data$weight))*asp
      
      dfm$varn <- as.numeric(dfm$variable)
      dfm <- transform(dfm, 
                       x = min(varn+offset+xid),
                       xend = max(varn+offset+xid),
                       tangens = max(midy)-min(midx)
                       )
      dfm$tangens <- with(dfm, tangens/max(xend-x)*plot.asp)
      dfm$width <- with(dfm, Freq/cos(atan(tangens)))
      dfm$width <- with(dfm, width*maxwidth/max(width))      
      dfm <- ddply(dfm, .(id), transform, 
                   y=c(midx[1], midy[1])[varn]
                   )
      
      r <- geom_ribbon(aes(x=as.numeric(variable)+offset+xid, 
                           ymin=y-width, ymax=y+width, group=id, 
                           fill=Nodeset),  alpha=alpha, data=dfm) #, drop=FALSE)
    }
    r
  }
  
  ## end helper function

  ## local variables
  variable <- NULL
  Freq <- NULL
  Nodeset <- NULL
  ypos <- NULL  
  
  gr <- list()
  for (i in 1:(length(vars)-1))
    gr[[i]] <- getRibbons(i,i+1)

  subdata <- data[,c("weight", unlist(vars))] 
  dfm <- melt(subdata, id.var="weight")
  names(dfm)[3] <- "Nodeset"
  dfm$Nodeset <- factor(dfm$Nodeset, levels=llist)
  
  llabels <- NULL
  if (label) {
    label.stats <- ddply(dfm, .(variable, Nodeset), summarize,
                         n = length(weight),
                         weight=sum(weight)
                         )
    maxWeight <- sum(label.stats$weight)/length(unique(label.stats$variable))
    label.stats$ypos <- cumsum(label.stats$weight)-(as.numeric(label.stats$variable)-1)*maxWeight
    label.stats$ypos <- label.stats$ypos-label.stats$weight/2

    if (is.null(text.offset)) text.offset <- 0
    label.stats$text.offset <- rep(text.offset, length=nrow(label.stats))
     
    varnames <- paste(unlist(vars), sep="|", collapse="|")
    label.stats$labels <- gsub(sprintf("(%s):(.*)",varnames),"\\2", as.character(label.stats$Nodeset))
    if (is.null(text.colour)) text.colour <- "grey20"
    label.stats$xoffs<-as.numeric(label.stats$variable)+0.01*text.shadow.x.offset+text.offset
    label.stats$yoffs<-label.stats$ypos-0.1*text.shadow.y.offset
    llabels <- list(geom_text(aes(x=as.numeric(variable)+0.01+text.offset, y=ypos, label=labels),
                        colour = text.colour, data=label.stats, angle=text.angle, size=text.size))   
    if (text.shadow) {
      if (is.null(text.shadow.colour)) text.shadow.colour = "grey90"
      llabels[[2]] <- geom_text(aes(x=xoffs, y=yoffs, label=labels),
                          colour = text.shadow.colour, data=label.stats, angle=text.angle, size=text.shadow.size) 
    }
  }
  theme.layer <- NULL
  if (!is.null(asp)) theme.layer <- theme(aspect.ratio=asp)
  ggplot() + geom_bar(aes(weight=weight, x=variable, fill=Nodeset, colour=Nodeset),  width=width, data=dfm) + 
             xlab("")  + gr + theme.layer + llabels + 
             scale_x_discrete(expand=c(0.1, 0.1)) 
  # theme(drop=FALSE)
}

