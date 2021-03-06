Image conversion to linedraw inspired in the Traveling Salesman Problem
-----------------------------------------------------------------------

![](https://github.com/julianlavila/PhotosR/blob/master/me.jpg%2020%)
![](https://github.com/julianlavila/PhotosR/blob/master/Me.png%2020%)

[Traveling Salesman
Problem](https://en.wikipedia.org/wiki/Travelling_salesman_problem) in
Wikipedia

### Load libraries

    library(imager)
    library(dplyr)
    library(ggplot2)
    library(scales)
    library(TSP)
    #output: github_document

### Load the image to convert

    # Point to the place where your image is stored
    file <- "me.jpg"

### convert to grayscale

    # Load, convert to grayscale, filter image (to convert it to bw) and sample
    load.image(file) %>% 
      grayscale() %>%
      threshold("45%") %>% 
      as.cimg() %>% 
      as.data.frame()  %>% 
      sample_n(18000, weight=(1-value)) %>% 
      select(x,y) -> data

### TSP distances

    # Compute distances and solve TSP (it may take a minute)
    as.TSP(dist(data)) %>% 
      solve_TSP(method = "arbitrary_insertion") %>% 
      as.integer() -> solution
    # Rearrange the original points according the TSP output
    data_to_plot <- data[solution,]

### Plot the linedraw

    # A little bit of ggplot to plot results
    ggplot(data_to_plot, aes(x,y)) +
      geom_path() +
      scale_y_continuous(trans=reverse_trans())+
      coord_fixed()+
      theme_void()

![](README_files/figure-markdown_strict/Plot-1.png)

    # Do you like the result? Save it! (Change the filename if you want)
    #ggsave("Me.png", dpi=600, width = 4, height = 5)
