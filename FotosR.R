# Load in packages
library(tidyverse)
library(imager)

# Point to the place where your image is stored
file <- "me.jpg"

# Load and convert to grayscale
load.image(file) %>%
  grayscale() -> img

# The image is summarized into s x s squares 
s <- 17

# Resume pixels using mean: this decreases drastically the resolution of the image
img %>% 
  as.data.frame() %>%
  mutate(x = cut(x, round(dim(img)[1]/s, 0), labels = FALSE),
         y = cut(y, round(dim(img)[2]/s, 0), labels = FALSE)) %>%
  group_by(x, y) %>%
  summarise(value = mean(value)) -> df

# Create new variable to be used to define size and color of the lines of tiles
df %>% mutate(z = cut(value, breaks = 20, labels = FALSE)) -> df

# Initialize plot 
plot <- ggplot()

# Resulting plot will be build with 20 layers: one layer per each different value of z 
for (i in 1:20){
  sub_data = df %>% filter(z==i)
  plot <- plot + geom_tile(aes(x, y),
                           size = 2*i/(20-1)-2/(20-1),
                           fill = "darkred",
                           col = paste0("gray", round(((100-5)*i)/(20-1)+5-(100-5)/(20-1), 0)),
                           data = df %>% filter(z==i))
}

# Last tweaks
plot +
  coord_fixed() +
  scale_y_reverse() +
  theme_void() -> plot

plot

ggsave("frankenstein_tiled.png", plot, height =  8 , width =  6)

######################
#Line draw

library(imager)
library(dplyr)
library(ggplot2)
library(scales)
library(TSP)

# Download the image
#urlfile="http://ereaderbackgrounds.com/movies/bw/Frankenstein.jpg"

#file="frankenstein.jpg"
#if (!file.exists(file)) download.file(urlfile, destfile = file, mode = 'wb')

# Load, convert to grayscale, filter image (to convert it to bw) and sample
load.image(file) %>% 
  grayscale() %>%
  threshold("45%") %>% 
  as.cimg() %>% 
  as.data.frame()  %>% 
  sample_n(18000, weight=(1-value)) %>% 
  select(x,y) -> data

# Compute distances and solve TSP (it may take a minute)
as.TSP(dist(data)) %>% 
  solve_TSP(method = "arbitrary_insertion") %>% 
  as.integer() -> solution

# Rearrange the original points according the TSP output
data_to_plot <- data[solution,]

# A little bit of ggplot to plot results
ggplot(data_to_plot, aes(x,y)) +
  geom_path() +
  scale_y_continuous(trans=reverse_trans())+
  coord_fixed()+
  theme_void()

# Do you like the result? Save it! (Change the filename if you want)
ggsave("frankyTSP.png", dpi=600, width = 4, height = 5)


###########################

library(imager)
library(tidyverse)

# Location of the photograph
file <- "frankenstein.jpg"

# Load, convert to grayscale, filter image (to convert it to bw) and sample
load.image(file) %>%
  grayscale() %>%  
  threshold("45%") %>%
  as.cimg() %>%
  as.data.frame() %>%
  filter(value == 0) %>%
  select(x, y) -> franky  

# Parameters: play with them!
l     <- 25 # longitude of lines 
d_min <-  2 # minimun distance to search attractors
d_max <- 22 # maximun distance to search attractors
d_rem <- 12 # distance to remove attractors


# Sample size
n <- 300

# Random sample of points from protograph
segments <- data.frame()

# We will compute 20 layers 
for(j in 1:70){
  
  # sample of points from photograph
  franky %>%
    sample_n(n) -> attractors
  
  # Initialization
  attractors %>%
    sample_n(1) %>%
    summarise(x = mean(x), y = mean(y)) %>% 
    mutate(parent = NA) %>%
    add_column(id = 1, .before = "x") -> nodes
  
  # let's colonize until less than 15000 attractors remain
  while(nrow(attractors) > 1500){
    
    # each attraction point is associated with the tree node that is closest to it
    merge(nodes, attractors, by = NULL, suffixes = c("_node","_attractor")) %>%
      mutate(d = sqrt((x_attractor - x_node)^2 + (y_attractor - y_node)^2)) -> distances_all
    
    # closest node to each attractor
    distances_all %>%
      group_by(x_attractor, y_attractor) %>%
      arrange(d) %>%
      slice(1) -> closests
    
    # keep those within of the radius of influence and normalize
    closests %>%
      ungroup() %>%
      filter(d > d_min, d < d_max) %>%
      mutate(x_dir = (x_attractor - x_node)/d,
             y_dir = (y_attractor - y_node)/d) %>%
      group_by(id, x_node, y_node) %>%
      summarise(x_dirs = sum(x_dir),
                y_dirs = sum(y_dir)) %>%
      mutate(x_norm = x_dirs/sqrt(x_dirs^2 + y_dirs^2),
             y_norm = y_dirs/sqrt(x_dirs^2 + y_dirs^2)) %>%
      ungroup() %>%
      transmute(x = x_node + sqrt(l)*cos(atan2(y_norm, x_norm)),
                y = y_node + sqrt(l)*sin(atan2(y_norm, x_norm)),
                parent = id) -> nodes_new
    
    # Add new nodes to the set of nodes
    add_column(nodes_new,
               id = seq(from = max(nodes$id)+1, by = 1, length.out = nrow(nodes_new)),
               .before = "x") %>% rbind(nodes) -> nodes
    
    # Remove closest attractors
    distances_all %>%
      filter(d < d_rem) %>%
      distinct(x = x_attractor, y = y_attractor) -> attractors_to_remove
    attractors %>%
      anti_join(attractors_to_remove, by = c("x", "y")) -> attractors
    
  }
  
  # Create segments
  nodes %>%
    inner_join(nodes, by = c("id" = "parent"), suffix = c("", "end")) %>%
    select(x, y, xend, yend) -> segments_tmp
  
  add_column(segments_tmp,
             drawing = j,
             .before = "x") -> segments_tmp
  
  segments %>% rbind(segments_tmp) -> segments  
}

# Draw result
ggplot() +
  geom_segment(aes(x = x, y = y, xend = xend, yend = yend, group = drawing),
               alpha = 0.4,
               data = segments) +
  coord_equal() +
  scale_y_reverse() +
  theme_void()
