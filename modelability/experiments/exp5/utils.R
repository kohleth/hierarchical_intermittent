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

myfeature=function(.ts_list,fn,...){
  foreach(ts=ichunk(.ts_list,chunkSize=1000),.final=function(x)unlist(x,use.names=F),...)%dopar%{
    unlist(lapply(ts,fn),use.names=F)
  }
}


## a port of https://github.com/benfulcher/hctsa/blob/34a92628bd13dec09ea137f0d7040c4be6176400/Operations/SB_CoarseGrain.m
## method = 'updown' only
sb_coarsegrain=function(y,numGroups=2){
  y=diff(y)
  th=quantile(y,seq(0,1,l=numGroups+1))
  th[1]=th[1]-1
  if(anyDuplicated(th))stop('quantiles for diff(y) not unique!')
  as.integer(cut(y,breaks=th))

}


## a port of https://github.com/benfulcher/hctsa/blob/master/Operations/FC_Surprise.m
## method = 'updown' and prior='dist' only
fc_surprise_dist_upd=function(y,numGroups=2,memory=5,numIters=500){
  yth=try(sb_coarsegrain(y,numGroups))
  if(inherits(yth,'try-error'))return(NA)
  N=length(yth)
  # rs=sample(N-memory)+memory  ## my ts is not that long
  # rs=sort(head(rs,numIters))  ## my ts is not that long
  rs=(memory+1):length(yth)
  store=sapply(1:length(rs),function(i)sum(yth[(rs[i]-memory):(rs[i]-1)]==yth[rs[i]])/memory)
  store[store==0]=1
  store=-log(store)
  mean(store)
}

sy_trend_meanYC=function(y,n=NULL){
  if(is.null(n)&is.ts(y)&frequency(y)>1)n=frequency(y)
  mean(cumsum(scale(head(y,n))))
}
