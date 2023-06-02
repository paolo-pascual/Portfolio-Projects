
# MEMBER
# Bautista, Rampel Jade R.
# Catacutan, Emiel H.
# Mercurio, Genesis D.
# Pascual, Christian Paolo M.







## TASK 1: Read cars_part1.csv and cars_part2.csv into tibble objects.


library(tidyverse)

cars1 <- read_csv("cars_part1.csv", 
                  col_names = T, 
                  col_types = list(col_character(),
                                   col_character(),
                                   col_factor(),
                                   col_factor(),
                                   col_number(),
                                   col_number()))


cars2 <- read_csv("cars_part2.csv", 
                  col_names = T, 
                  col_types = list(col_character(),
                                   col_character(),
                                   rep(col_number(),5)))

str(cars1) 
str(cars2)


## TASK 2: Combine cars_part1 and cars_part2 into a single data frame.


carsall <- left_join(cars1, cars2, by = "Model", suffix = c("",".y")) %>%
  select(-ends_with(".y"))




## TASK 3: Compute the minimum, maximum, and average price --
#          (MSRP – mean standard retail price) of Sedantype cars for each car maker


carsall %>% filter(Type == "Sedan") %>% 
  group_by(Make) %>%
  summarise(min_price = min(MSRP, na.rm = T),
            max_price = max(MSRP, na.rm = T),
            mean_price = mean(MSRP, na.rm = T)) %>%
  View()



## TASK 4: Compute the average price of Sedan-type cars by origin (USA, Asia, Europe). 
#          Then, list all sedan-type car models whose MSRP is below the origin’s average. 
#          Sort the car model by origin, then by price in decreasing order.


orgn_ave <- carsall %>% 
            filter(Type == "Sedan") %>% 
            group_by(Origin) %>%
            summarise(mean_price = mean(MSRP))

left_join(carsall, orgn_ave, by = "Origin") %>% 
  filter(Type == "Sedan", MSRP < mean_price) %>% 
  arrange(Origin, desc(MSRP)) %>%
  select("Type","Model", "Origin", "MSRP", "mean_price") %>%
  View()



## TASK 5: Randomly partition the combined data from task 2 
#          into 3 non-overlapping data sets. 20% of 
#          observations in “subset1”, 30% of observations in “subset2”, and 50% 
#          of observations in “subset3”.


prop <- c(twenty = .2, thirty = .3, fifty = .5)

g <- sample(cut(
  seq(nrow(carsall)), 
  nrow(carsall)*cumsum(c(0,prop)),
  labels = names(prop)))

res <-  split(carsall, g)



sub1 <- res$twenty 
sub2 <- res$thirty
sub3 <- res$fifty 









