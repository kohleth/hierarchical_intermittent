permu_en=function(ts,M=5){
  N=length(ts)
  subts=function(.ts,l,exclude_last=T){
    N=length(.ts)
    if(exclude_last)return(lapply(1:(N-l),function(i).ts[i:(i+l-1)]))
    lapply(1:(N-l+1),function(i).ts[i:(i+l-1)])
  }
  x_M=subts(ts,M,exclude_last = F)
  
  pattern=lapply(x_M,rank)
  p=pattern%>%lapply(paste,collapse='-')%>%unlist%>%table
  p=p/sum(p)
  -sum(p*log2(p))
}

mycroston=function (y, h = 10, alpha = 0.1, x = y) 
{
  if (sum(x < 0) > 0) {
    stop("Series should not contain negative values")
  }
  out <- forecast:::croston2(x, h, alpha,nofit=TRUE)
  out=list(mean = out)
  out$x <- x
  if (!is.null(out$fitted)) {
    out$residuals <- x - out$fitted
  }
  out$method <- "Croston's method"
  out$series <- deparse(substitute(y))
  return(structure(out, class = "forecast"))
}

myfeature=function(.ts_list,fn,packages=NULL){
  foreach(ts=ichunk(.ts_list,chunkSize=1000),.final=function(x)unlist(x,use.names=F),.packages=packages)%dopar%{
    unlist(lapply(ts,fn),use.names=F)
  }
}
