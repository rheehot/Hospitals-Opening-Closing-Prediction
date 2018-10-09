# load necessary libraries
library(tidyverse)
library(DataExplorer)
library(lubridate)

# --------------------------------------
# --------------------------------------

# read the files
train_dta <- read.csv("train.csv")
test_dta  <- read.csv("test.csv")

# --------------------------------------
# --------------------------------------

# look at loaded/parsed data
#glimpse(train_dta)
#summary(train_dta)
#create_report(train_dta)

# --------------------------------------
# --------------------------------------

# correct parsing of the variables: 'employee1' & 'employee2'
train_dta$employee1 <- 
  train_dta$employee1 %>% 
  as.character() %>%            # convert to character...
  as.numeric()                  # then convert to numeric (non-numerics automatically coerced to NA)

train_dta$employee2 <- 
  train_dta$employee2 %>% 
  as.character() %>%            # convert to character...
  as.numeric()                  # then convert to numeric (non-numerics automatically coerced to NA)

test_dta$employee1 <- 
  test_dta$employee1 %>% 
  as.character() %>%            # convert to character...
  as.numeric()                  # then convert to numeric (non-numerics automatically coerced to NA)

test_dta$employee2 <- 
  test_dta$employee2 %>% 
  as.character() %>%            # convert to character...
  as.numeric()                  # then convert to numeric (non-numerics automatically coerced to NA)

# ---------

# correct parsing of 'instkind'
levels(train_dta$instkind)[levels(train_dta$instkind) == ''] <- NA
levels(test_dta$instkind) [levels( test_dta$instkind) == ''] <- NA

# ---------

# correct parsing of 'openDate'
train_dta$openDate <- as.Date(as.character(train_dta$openDate), format = "%Y%m%d")
test_dta$openDate  <- as.Date(as.character( test_dta$openDate), format = "%Y%m%d")

# ---------

# correct parsing of 'OC'
levels(train_dta$OC) <- trimws(levels(train_dta$OC))   # trims levels (' close'  -->  'close')
levels(test_dta$OC)  <- trimws(levels( test_dta$OC))   # trims levels (' close'  -->  'close')

# --------------------------------------
# --------------------------------------

### fill missing values ###

# instkind
hospital_type_counts <- table(train_dta$instkind)   # contains counts of each type of hospital
most_frequent_hospital_type <- levels(train_dta$instkind)[hospital_type_counts == max(hospital_type_counts)]
train_dta$instkind[is.na(train_dta$instkind)] <- most_frequent_hospital_type   # 'nursing_hospital'
test_dta$instkind[is.na(test_dta$instkind)]  <- most_frequent_hospital_type   # 'nursing_hospital'

# ---------
 
# employee1, employee2
# if either of 'employee1' or 'employee2' is NA, then the NA-valued one will take the value of the other
# if both are NA, then they will stay NA
for (i in 1:nrow(train_dta)) {
  if (is.na(train_dta[i,]$employee1)) train_dta[i,]$employee1 <- train_dta[i,]$employee2
  if (is.na(train_dta[i,]$employee2)) train_dta[i,]$employee2 <- train_dta[i,]$employee1
}
for (i in 1:nrow(test_dta)) {
  if (is.na(test_dta[i,]$employee1)) test_dta[i,]$employee1 <- test_dta[i,]$employee2
  if (is.na(test_dta[i,]$employee2)) test_dta[i,]$employee2 <- test_dta[i,]$employee1
}

# ---------

# bedCount
bedCounts_per_hospital_type <- 
  train_dta %>% 
  select(instkind, bedCount) %>% 
  group_by(instkind) %>% 
  summarise(bedCountAvg = median(bedCount, na.rm = T))

for (i in 1:nrow(train_dta)) {
  if (is.na(train_dta[i,]$bedCount)) {
    train_dta[i,]$bedCount <- 
      bedCounts_per_hospital_type$bedCountAvg[bedCounts_per_hospital_type$instkind == train_dta[i,]$instkind]
  }
}

# remove dental_clinic as this hospital type does not exist in test data
bedCounts_per_hospital_type <- 
  bedCounts_per_hospital_type %>% 
  filter(instkind != 'dental_clinic')
bedCounts_per_hospital_type$instkind <- factor(bedCounts_per_hospital_type$instkind)

for (i in 1:nrow(test_dta)) {
  if (is.na(test_dta[i,]$bedCount)) {
    test_dta[i,]$bedCount <- 
      bedCounts_per_hospital_type$bedCountAvg[bedCounts_per_hospital_type$instkind == test_dta[i,]$instkind]
  }
}

# ---------

# takes a vector and replaces its NA values with the mean of the vector
meanFiller <- function(x) {x[is.na(x)] <- mean(x, na.rm = T); x}

# ---------

# variables 8-55  (the numerical variables)
train_dta[,7:55] <-        # 7th variable is 'instkind', the variable to group by
  train_dta[,7:55] %>% 
  group_by(instkind) %>%   # group by instkind
  mutate_all(meanFiller)   # get mean per group & use to fill NAs of each group
  #summarise_all(mean, na.rm = T)

test_dta[,7:55] <-        # 7th variable is 'instkind', the variable to group by
  test_dta[,7:55] %>% 
  group_by(instkind) %>%   # group by instkind
  mutate_all(meanFiller)   # get mean per group & use to fill NAs of each group

# ---------

# ownerChange
train_dta$ownerChange <- 
  train_dta$ownerChange %>% 
  replace_na('same')

test_dta$ownerChange <- 
  test_dta$ownerChange %>% 
  replace_na('same')

# --------------------------------------
# --------------------------------------

# feature engineering

# the variables suffixed 1 and 2
# get differences (training data)
train_dta$revenue3           <- train_dta$revenue1           - train_dta$revenue2
train_dta$salescost3         <- train_dta$salescost1         - train_dta$salescost2
train_dta$sga3               <- train_dta$sga1               - train_dta$sga2
train_dta$salary3            <- train_dta$salary1            - train_dta$salary2
train_dta$noi3               <- train_dta$noi1               - train_dta$noi2
train_dta$noe3               <- train_dta$noe1               - train_dta$noe2
train_dta$interest3          <- train_dta$interest1          - train_dta$interest2
train_dta$ctax3              <- train_dta$ctax1              - train_dta$ctax2
train_dta$profit3            <- train_dta$profit1            - train_dta$profit2
train_dta$liquidAsset3       <- train_dta$liquidAsset1       - train_dta$profit2
train_dta$quickAsset3        <- train_dta$quickAsset1        - train_dta$quickAsset2
train_dta$receivableS3       <- train_dta$receivableS1       - train_dta$receivableS2
train_dta$inventoryAsset3    <- train_dta$inventoryAsset1    - train_dta$inventoryAsset2
train_dta$nonCAsset3         <- train_dta$nonCAsset1         - train_dta$nonCAsset2
train_dta$tanAsset3          <- train_dta$tanAsset1          - train_dta$tanAsset2
train_dta$OnonCAsset3        <- train_dta$OnonCAsset1        - train_dta$OnonCAsset2
train_dta$debt3              <- train_dta$debt1              - train_dta$debt1
train_dta$liquidLiabilities3 <- train_dta$liquidLiabilities1 - train_dta$liquidLiabilities2
train_dta$shortLoan3         <- train_dta$shortLoan1         - train_dta$shortLoan2
train_dta$NCLiabilities3     <- train_dta$NCLiabilities1     - train_dta$NCLiabilities2
train_dta$longLoan3          <- train_dta$longLoan1          - train_dta$longLoan2
train_dta$netAsset3          <- train_dta$netAsset1          - train_dta$netAsset2
train_dta$surplus3           <- train_dta$surplus1           - train_dta$surplus2
train_dta$employee3          <- train_dta$employee1          - train_dta$employee2

# get differences (testing data)
test_dta$revenue3           <- test_dta$revenue1           - test_dta$revenue2
test_dta$salescost3         <- test_dta$salescost1         - test_dta$salescost2
test_dta$sga3               <- test_dta$sga1               - test_dta$sga2
test_dta$salary3            <- test_dta$salary1            - test_dta$salary2
test_dta$noi3               <- test_dta$noi1               - test_dta$noi2
test_dta$noe3               <- test_dta$noe1               - test_dta$noe2
test_dta$interest3          <- test_dta$interest1          - test_dta$interest2
test_dta$ctax3              <- test_dta$ctax1              - test_dta$ctax2
test_dta$profit3            <- test_dta$profit1            - test_dta$profit2
test_dta$liquidAsset3       <- test_dta$liquidAsset1       - test_dta$profit2
test_dta$quickAsset3        <- test_dta$quickAsset1        - test_dta$quickAsset2
test_dta$receivableS3       <- test_dta$receivableS1       - test_dta$receivableS2
test_dta$inventoryAsset3    <- test_dta$inventoryAsset1    - test_dta$inventoryAsset2
test_dta$nonCAsset3         <- test_dta$nonCAsset1         - test_dta$nonCAsset2
test_dta$tanAsset3          <- test_dta$tanAsset1          - test_dta$tanAsset2
test_dta$OnonCAsset3        <- test_dta$OnonCAsset1        - test_dta$OnonCAsset2
test_dta$debt3              <- test_dta$debt1              - test_dta$debt1
test_dta$liquidLiabilities3 <- test_dta$liquidLiabilities1 - test_dta$liquidLiabilities2
test_dta$shortLoan3         <- test_dta$shortLoan1         - test_dta$shortLoan2
test_dta$NCLiabilities3     <- test_dta$NCLiabilities1     - test_dta$NCLiabilities2
test_dta$longLoan3          <- test_dta$longLoan1          - test_dta$longLoan2
test_dta$netAsset3          <- test_dta$netAsset1          - test_dta$netAsset2
test_dta$surplus3           <- test_dta$surplus1           - test_dta$surplus2
test_dta$employee3          <- test_dta$employee1          - test_dta$employee2

# ---------

# hospital age
train_dta$age <- Sys.Date() - train_dta$openDate
test_dta$age  <- Sys.Date() - test_dta$openDate

# --------------------------------------
# --------------------------------------

# special handling for employee3
train_dta$employee3 <- meanFiller(train_dta$employee3)
test_dta$employee3  <- meanFiller(test_dta$employee3)

# employee1 still has some NAs, let's deal with those by the way
train_dta$employee1 <- meanFiller(train_dta$employee1)
test_dta$employee1  <- meanFiller(test_dta$employee1)

# --------------------------------------
# --------------------------------------

# special handling for 'age' --> turns out that openDate has a single NA value in the test data
test_dta$age <- meanFiller(test_dta$age)  # fill the NA value with mean of variable

# --------------------------------------
# --------------------------------------

# remove variables 
train_dta <- train_dta[,-c(8:55)]                      # remove original numerical variables (suffixed 1 and 2)
train_dta <- train_dta %>% select(-employee2, -openDate, -sgg, -sido)   # remove employee2, openDate, sgg, sido
test_dta <- test_dta[,-c(8:55)]
test_dta <- test_dta %>% select(-employee2, -openDate, -sgg, -sido)

# --------------------------------------
# --------------------------------------

# special handling for age
# age currently contains dat difference in days, we want to force into a numeric type to prevent issues later
train_dta$age <- as.numeric(train_dta$age)  # convert age to integer
test_dta$age  <- as.numeric(test_dta$age)   # convert age to integer

# --------------------------------------
# --------------------------------------

# prepare data for modeling (transformation)

# log transformation for numerical variables (bedCount, employee1 & variables suffixed 3)
# Before applying log transformation, we need to ensure that minimum value for each variable is 1
train_dta_log_num <- train_dta
test_dta_log_num <- test_dta

mylog <- function(x) {
  x <- log(x - min(x) + 1)
  x
}

train_dta_log_num[,c(3,5,7:31)] <- 
  train_dta_log_num[,c(3,5,7:31)] %>% 
  mutate_all(mylog)
test_dta_log_num[,c(3,5,7:31)] <- 
  test_dta_log_num[,c(3,5,7:31)] %>% 
  mutate_all(mylog)

write_csv(train_dta_log_num, '1.train_dta_log_num.csv')
write_csv(test_dta_log_num,  '1.test_dta_log_num.csv')

# ---------

# transformation for numerical variables to range [0, 1] (min-max normalization)
train_dta_min_max <- train_dta
test_dta_min_max <- test_dta

myminmax <- function(x) {
  minn <- min(x)
  maxx <- max(x)
  x <- (x - minn) / (maxx - minn)
  x
}

train_dta_min_max[,c(3,5,7:31)] <- 
  train_dta_min_max[,c(3,5,7:31)] %>% 
  mutate_all(myminmax)
test_dta_min_max[,c(3,5,7:31)] <- 
  test_dta_min_max[,c(3,5,7:31)] %>% 
  mutate_all(myminmax)

write_csv(train_dta_min_max, '2.train_dta_min_max.csv')
write_csv(test_dta_min_max,  '2.test_dta_min_max.csv')

# ---------

# transformation for numerical variables: log transformation followed by min-max normalization
train_dta_log_num_min_max <- train_dta
test_dta_log_num_min_max <- test_dta

mylognumminmax <- function(x) {
  x <- mylog(x)
  x <- myminmax(x)
  x
}

train_dta_log_num_min_max[,c(3,5,7:31)] <- 
  train_dta_log_num_min_max[,c(3,5,7:31)] %>% 
  mutate_all(mylognumminmax)
test_dta_log_num_min_max[,c(3,5,7:31)] <- 
  test_dta_log_num_min_max[,c(3,5,7:31)] %>% 
  mutate_all(mylognumminmax)

write_csv(train_dta_log_num_min_max, '3.train_dta_log_num_min_max.csv')
write_csv(test_dta_log_num_min_max,  '3.test_dta_log_num_min_max.csv')

# ---------

# transformation for numerical variables: Z-transform
train_dta_z_transform <- train_dta
test_dta_z_transform <- test_dta

myztransform <- function(x) {
  x <- (x - mean(x)) / sd(x)
  x
}

train_dta_z_transform[,c(3,5,7:31)] <- 
  train_dta_z_transform[,c(3,5,7:31)] %>% 
  mutate_all(myztransform)
test_dta_z_transform[,c(3,5,7:31)] <- 
  test_dta_z_transform[,c(3,5,7:31)] %>% 
  mutate_all(myztransform)

write_csv(train_dta_z_transform, '4.train_dta_z_transform.csv')
write_csv(test_dta_z_transform,  '4.test_dta_z_transform.csv')

# ---------

# transformation for numerical variables: Z-transform per hospital type
train_dta_z_transform_per_hosp_type <- train_dta
test_dta_z_transform_per_hosp_type <- test_dta

train_dta_z_transform_per_hosp_type[,c(3:5,7:31)] <-       # include instkind to use as grouping variable
  train_dta_z_transform_per_hosp_type[,c(3:5,7:31)] %>% 
  group_by(instkind) %>% 
  mutate_all(myztransform)
test_dta_z_transform_per_hosp_type[,c(3:5,7:31)] <- 
  test_dta_z_transform_per_hosp_type[,c(3:5,7:31)] %>% 
  group_by(instkind) %>% 
  mutate_all(myztransform)

write_csv(train_dta_z_transform_per_hosp_type, '5.train_dta_z_transform_per_hosp_type.csv')
write_csv(test_dta_z_transform_per_hosp_type,  '5.test_dta_z_transform_per_hosp_type.csv')

# --------------------------------------
# --------------------------------------

# # normalize by variables suffixed 2 to get ratios
# train_dta$revenue3           <- train_dta$revenue3           / train_dta$revenue2
# train_dta$salescost3         <- train_dta$salescost3         / train_dta$salescost2
# train_dta$sga3               <- train_dta$sga3               / train_dta$sga2
# train_dta$salary3            <- train_dta$salary3            / train_dta$salary2
# train_dta$noi3               <- train_dta$noi3               / train_dta$noi2
# train_dta$noe3               <- train_dta$noe3               / train_dta$noe2
# train_dta$interest3          <- train_dta$interest3          / train_dta$interest2
# train_dta$ctax3              <- train_dta$ctax3              / train_dta$ctax2
# train_dta$profit3            <- train_dta$profit3            / train_dta$profit2
# train_dta$liquidAsset3       <- train_dta$liquidAsset3       / train_dta$profit2
# train_dta$quickAsset3        <- train_dta$quickAsset3        / train_dta$quickAsset2
# train_dta$receivableS3       <- train_dta$receivableS3       / train_dta$receivableS2
# train_dta$inventoryAsset3    <- train_dta$inventoryAsset3    / train_dta$inventoryAsset2
# train_dta$nonCAsset3         <- train_dta$nonCAsset3         / train_dta$nonCAsset2
# train_dta$tanAsset3          <- train_dta$tanAsset3          / train_dta$tanAsset2
# train_dta$OnonCAsset3        <- train_dta$OnonCAsset3        / train_dta$OnonCAsset2
# train_dta$debt3              <- train_dta$debt3              / train_dta$debt1
# train_dta$liquidLiabilities3 <- train_dta$liquidLiabilities3 / train_dta$liquidLiabilities2
# train_dta$shortLoan3         <- train_dta$shortLoan3         / train_dta$shortLoan2
# train_dta$NCLiabilities3     <- train_dta$NCLiabilities3     / train_dta$NCLiabilities2
# train_dta$longLoan3          <- train_dta$longLoan3          / train_dta$longLoan2
# train_dta$netAsset3          <- train_dta$netAsset3          / train_dta$netAsset2
# train_dta$surplus3           <- train_dta$surplus3           / train_dta$surplus2
# train_dta$employee3          <- train_dta$employee3          / train_dta$employee2

# # normalize by variables suffixed 2 to get ratios
# test_dta$revenue3           <- test_dta$revenue3           / test_dta$revenue2
# test_dta$salescost3         <- test_dta$salescost3         / test_dta$salescost2
# test_dta$sga3               <- test_dta$sga3               / test_dta$sga2
# test_dta$salary3            <- test_dta$salary3            / test_dta$salary2
# test_dta$noi3               <- test_dta$noi3               / test_dta$noi2
# test_dta$noe3               <- test_dta$noe3               / test_dta$noe2
# test_dta$interest3          <- test_dta$interest3          / test_dta$interest2
# test_dta$ctax3              <- test_dta$ctax3              / test_dta$ctax2
# test_dta$profit3            <- test_dta$profit3            / test_dta$profit2
# test_dta$liquidAsset3       <- test_dta$liquidAsset3       / test_dta$profit2
# test_dta$quickAsset3        <- test_dta$quickAsset3        / test_dta$quickAsset2
# test_dta$receivableS3       <- test_dta$receivableS3       / test_dta$receivableS2
# test_dta$inventoryAsset3    <- test_dta$inventoryAsset3    / test_dta$inventoryAsset2
# test_dta$nonCAsset3         <- test_dta$nonCAsset3         / test_dta$nonCAsset2
# test_dta$tanAsset3          <- test_dta$tanAsset3          / test_dta$tanAsset2
# test_dta$OnonCAsset3        <- test_dta$OnonCAsset3        / test_dta$OnonCAsset2
# test_dta$debt3              <- test_dta$debt3              / test_dta$debt1
# test_dta$liquidLiabilities3 <- test_dta$liquidLiabilities3 / test_dta$liquidLiabilities2
# test_dta$shortLoan3         <- test_dta$shortLoan3         / test_dta$shortLoan2
# test_dta$NCLiabilities3     <- test_dta$NCLiabilities3     / test_dta$NCLiabilities2
# test_dta$longLoan3          <- test_dta$longLoan3          / test_dta$longLoan2
# test_dta$netAsset3          <- test_dta$netAsset3          / test_dta$netAsset2
# test_dta$surplus3           <- test_dta$surplus3           / test_dta$surplus2
# test_dta$employee3          <- test_dta$employee3          / test_dta$employee2

