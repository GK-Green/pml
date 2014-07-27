# PML course project

# Including necessary libraries

library(caret)

# Reading training data

OriData <- read.csv("pml-training.csv", header = TRUE, row.names = 1)
OriTest <- read.csv("pml-testing.csv", header = TRUE, row.names = 1)
numCase <- nrow(OriData)

# Cleaning data

# Handle missing values
# The percentage of the missing values of each column is evaluated
# The columns has more than 95% of the missing values are removed
# The user_name feature is removed because the nature of the project
# The action should not depend on person, and it's varified by
# ploting user_name vs the classe

nacol <- sapply(OriData, function(x) sum(is.na(x)|x==""))
data  <- OriData[,!(nacol/numCase > 0.95)]
data$cvtd_timestamp <- as.numeric(strptime(as.character(data$cvtd_timestamp), 
                                format = "%d/%m/%Y %H:%M"))
data  <- data[,-1]

# Detection of non-variate/zero covariates/features

nsv    <- nearZeroVar(as.matrix(data), saveMetrics = TRUE)
data   <- data[,nsv$nzv == FALSE]

rm(OriData)

# Split data to training (0.6), validation (0.2), and testing (0.2) set

set.seed(26)
Intrain    <- createDataPartition(data[,57], p = 0.8, list = FALSE)
training   <- data[Intrain,]
testing    <- data[-Intrain,]
InValid    <- createDataPartition(training[,57], p = 0.25, list = FALSE)
validation <- training[InValid,]
training   <- training[-InValid,]
coln       <- colnames(data)

rm(data, Intrain, InValid)

# Transform data

prep1            <- preProcess(training[,-57], method = c("center","scale"))
training[,-57]   <- predict(prep1, training[,-57])
validation[,-57] <- predict(prep1, validation[,-57])
testing[,-57]    <- predict(prep1, testing[,-57])

# Feature scanning to find stewed data

# abnormal <- numeric(0)
# for (i in 1:ncol(training)){
#   hist(as.numeric(training[,i]), main = colnames(training)[i])
#   x <- readline("1. stop 2. mark: ")
#   if (x ==1 ) break
#   else if (x==2) abnormal <- cbind(abnormal,i)
# }

# Remove outliers 

# summary(training[,42])
# summary(training[,35])
# summary(training[,9])
# summary(training[,17])
a <- which(training[,42] < -11)
a <- c(a, which(training[,35] < -100))
a <- c(a, which(training[,9]  > 8))
# a <- c(a, which(training[,17]  > 7))
training <- training[-a,]

rm(a)

# Detection of correlation between features
# If there is correlation between features (pca_condition is not 0)
# Perform PCA

comatrix       <- abs(cor(training[,-57]))
diag(comatrix) <- 0
pca_condition  <- length(which(comatrix > 0.8, arr.ind = F)) != 0

if (pca_condition) {
  prep2 <- preProcess(training[,-57], method = "pca", thres = 0.95)
  training   <- cbind(predict(prep2,training[,-57]),classe = training[,57])
  validation <- cbind(predict(prep2,validation[,-57]),classe = validation[,57])
  testing    <- cbind(predict(prep2,testing[,-57]),classe = testing[,57])
}

rm(comatrix, pca_condition)


# All preprocess together for new data (eg. pml-testing.csv)

prepall <- function(x){
  x <- x[,coln[-57]]
  x$cvtd_timestamp <- as.numeric(strptime(as.character(x$cvtd_timestamp), 
                                             format = "%d/%m/%Y %H:%M"))
  predict(prep2,predict(prep1, x))
}

# Training data

# gbmGrid <-  expand.grid(interaction.depth = c(5, 10),n.trees = c(1,3,5)*100,shrinkage = 0.1)
# M_gbm  <- train(classe ~., data = training, method = "gbm", verbose = FALSE, tuneGrid = gbmGrid)
# M_svmL <- train(classe ~., data = training, method = "svmLinear")
# M_svmR <- train(classe ~., data = training, method = "svmRadial")
# M_rf   <- train(classe ~., data = training, method = "rf")

load("M_rf.RData")
load("M_svmL.RData")
load("M_svmR.RData")
load("M_gbm.RData")

# In sample accuracy (training set)
rfIn     <- max(M_rf$results$Accuracy)
gbmIn    <- max(M_gbm$results$Accuracy)
svmLIn   <- max(M_svmL$results$Accuracy)
svmRIn   <- max(M_svmR$results$Accuracy)

ModelNam <- 1:4
names(ModelNam) <- c("SVM_L","SVM_R","GBM","RF")
InSamErr <- c(svmLIn, svmRIn , gbmIn, rfIn)

# Out of sample accuracy (validation set)
rfOut    <- confusionMatrix(predict(M_rf$finalModel,
                                    validation[,-29]),validation[,29])
gbmOut   <- confusionMatrix(predict(M_gbm,
                                    validation[,-29]),validation[,29])
svmLOut  <- confusionMatrix(predict(M_svmL$finalModel,
                                    validation[,-29]),validation[,29])
svmROut  <- confusionMatrix(predict(M_svmR$finalModel,
                                    validation[,-29]),validation[,29])