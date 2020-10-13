library(tidyverse)
world <- map_data("world")
names(data1)[1] <- "region"
cor_map <- left_join(world, data, by="region")

g <- ggplot()+geom_polygon(data=cor_map, aes(x = long, y= lat, group=group,
                                               fill = corruption), color = "black")+
  labs(x="", y="", title="Corruption Index by Country")+
  theme_classic()+theme(axis.ticks.y=element_blank(), axis.text.y=element_blank(),
                        axis.ticks.x =element_blank(), axis.text.x=element_blank())
g <- g+ scale_fill_distiller(name="Corruption Score", palette = "Purples", direction = 1, na.value = "white")         
