---
README
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Line draw inspired in Traveling Salesman Problem

![Original](https://github.com/julianlavila/PhotosR/mePNG.png | width=50) <br />

![Final](https://github.com/julianlavila/PhotosR/Me.png | width=500)

[Traveling Salesman Problem](https://en.wikipedia.org/wiki/Travelling_salesman_problem) in Wikipedia


### Load libraries
```{r libraries , message= FALSE}
library(imager)
library(dplyr)
library(ggplot2)
library(scales)
library(TSP)
```

### Load the image to convert

```{r load , message=FALSE}
# Point to the place where your image is stored
file <- "me.jpg"
```

### convert to grayscale
```{r conversion , message=FALSE}
# Load, convert to grayscale, filter image (to convert it to bw) and sample
load.image(file) %>% 
  grayscale() %>%
  threshold("45%") %>% 
  as.cimg() %>% 
  as.data.frame()  %>% 
  sample_n(18000, weight=(1-value)) %>% 
  select(x,y) -> data
```

### TSP distances 
```{r TSP , message=FALSE}
# Compute distances and solve TSP (it may take a minute)
as.TSP(dist(data)) %>% 
  solve_TSP(method = "arbitrary_insertion") %>% 
  as.integer() -> solution
# Rearrange the original points according the TSP output
data_to_plot <- data[solution,]
```

### Plot the linedraw
```{r Plot, message=FALSE}
# A little bit of ggplot to plot results
ggplot(data_to_plot, aes(x,y)) +
  geom_path() +
  scale_y_continuous(trans=reverse_trans())+
  coord_fixed()+
  theme_void()

# Do you like the result? Save it! (Change the filename if you want)
#ggsave("Me.png", dpi=600, width = 4, height = 5)
```

