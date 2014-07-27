abnormal <- numeric(0)
for (i in 1:ncol(data)){
  hist(as.numeric(data[,i]), main = colnames(data)[i])
  x <- readline("1. stop 2. mark: ")
  if (x ==1 ) break
  else if (x==2) abnormal <- cbind(abnormal,i)
}

outliers <- function(x, thres = 1.5) {
  n <- ncol(x)
  nout <- numeric(0)
  for (i in 1:n){
    temp <- numeric(0)
    LH   <- abs(min(x[,i]))
    RH   <- abs(max(x[,i]))
    if (LH > thres*RH) {
      temp <- which(x[,i] < -thres*max(x[,i]))
      temp <- rbind(temp,rep(i,length = length(temp)))
      nout <- cbind(nout,temp)
    } else if (RH > thres*LH){
      temp <- which(x[,i] > -thres*min(x[,i]))
      temp <- rbind(temp,rep(i,length = length(temp)))
      nout <- cbind(nout,temp)
    }
  }
  nout
}