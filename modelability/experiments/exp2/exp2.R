library(forecast)
library(pracma)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)
library(patchwork)
library(glarma)

permu_en=function(ts,M=3,normalize=T){
  if(M<3|M>5)stop('M must be 3, 4, or 5!')
  N=length(ts)
  subts=function(.ts,l,exclude_last=T){
    N=length(.ts)
    if(exclude_last)return(lapply(1:(N-l),function(i).ts[i:(i+l-1)]))
    lapply(1:(N-l+1),function(i).ts[i:(i+l-1)])
  }
  x_M=subts(ts,M,exclude_last = F)
  
  pattern=lapply(x_M,rank,ties.method='min') ## Bian (2012)'s equal rank approach
  p=pattern%>%lapply(paste,collapse='-')%>%unlist%>%table
  p=p/sum(p)
  if(normalize)return(-sum(p*log2(p))/log2(ifelse(M==3,13,ifelse(M==4,73,501))) )## see table 1 of Bian (2012)
  -sum(p*log2(p))
}

my_en=function(ts,M=3,normalize=F){
  if(length(ts[ts!=0])<2)return(NA)
  p0=mean(ts==0)
  p1=1-p0
  # -(p0*log2(p0)+p1*log2(p1))+p1*permu_en(ts,normalize = normalize,M=M)
  -(p0*log2(p0)+p1*log2(p1))+p1*permu_en(ts[ts!=0],normalize = normalize,M=M)
  
}

in_sample_naive_rmse=function(ts,seasonal=F){
  freq=ifelse(seasonal,frequency(ts),1)
  fc=c(rep(NA,freq),stats::lag(ts,-freq))%>%head(length(ts))
  sqrt(mean((ts-fc)^2,na.rm=T))
}


expsmooth::carparts%>%
  apply(2,function(.x)length(na.omit(.x)))%>%
  table

ts_list=expsmooth::carparts%>%
  as.list%>%
  Filter(function(.x)length(na.omit(.x))==51,.)

h=12

train_ts_list=lapply(ts_list,head,51-h)
test_ts_list=lapply(ts_list,tail,h)

X=tibble(train=train_ts_list)%>%
  mutate(ts=names(train))%>%
  inner_join(
    tibble(test=test_ts_list)%>%
      mutate(ts=names(test))
  )%>%
  filter(!map_lgl(train,~max(tail(.,frequency(.)))==0))


Xfeatures=X%>%
  mutate(spectral_en=map_dbl(train,~try(tsfeatures::entropy(.))),
         sample_en=map_dbl(train,~try(pracma::sample_entropy(.))),
         permu_en=map_dbl(train,~try(permu_en(.))),
         stlf=map(train,~try(tsfeatures::stl_features(.))),
         trendS=map_dbl(stlf,~ifelse(inherits(.,'try-error'),NA,.['trend'])),
         seasonalS=map_dbl(stlf,~ifelse(inherits(.,'try-error'),NA,.['seasonal_strength'])),
         p0=map_dbl(train,~try(mean(.==0))),
         lumpiness=map_dbl(train,tsfeatures::lumpiness),
         stability=map_dbl(train,tsfeatures::stability),
         in_naive_rmse=map_dbl(train,in_sample_naive_rmse,seasonal=F),
         in_snaive_rmse=map_dbl(train,in_sample_naive_rmse,seasonal=T),
         in_sd=map_dbl(train,sd),
         in_0_sd=map_dbl(train,~sqrt(mean(.^2))),
         in_n_r=in_naive_rmse/in_sd,
         in_sn_r=in_snaive_rmse/in_sd,
         spr=spectral_en/(1-p0),
         ser=sample_en/(1-p0),
         per=permu_en/(1-p0))%>%
  select(-test,-train,-stlf)


Xets=X%>%
  transmute(etsf=map(train,~forecast(ets(.),h=h,PI=FALSE)),
         ets_acc=map2(etsf,test,accuracy),
         ets_mase=map_dbl(ets_acc,~.[2,'MASE']))

Xstl=X%>%
  transmute(stlf=map(train,~stlf(.,h=h,s.window='periodic')),
         stl_acc=map2(stlf,test,accuracy),
         stl_mase=map_dbl(stl_acc,~.[2,'MASE']))

Xcros=X%>%
  transmute(crosf=map(train,~croston(.,h=h)),
         cros_acc=map2(crosf,test,accuracy),
         cros_mase=map_dbl(cros_acc,~.[2,'MASE']))

Xnaive=X%>%
  transmute(naivef=map(train,~naive(.,h=h)),
         naive_acc=map2(naivef,test,accuracy),
         naive_mase=map_dbl(naive_acc,~.[2,'MASE']))

Xsnaive=X%>%
  transmute(snaivef=map(train,~snaive(.,h=h)),
         snaive_acc=map2(snaivef,test,accuracy),
         snaive_mase=map_dbl(snaive_acc,~.[2,'MASE']))

Xmean=X%>%
  transmute(meanf=map(train,~meanf(.,h=h)),
            mean_acc=map2(meanf,test,accuracy),
            mean_mase=map_dbl(mean_acc,~.[2,'MASE']))

# glarmafc=function(y,h,phiLags=1){
#   X=matrix(rep(1,length(y)),dimnames=list(NULL,'Intercept'))
#   mod=glarma::glarma(y=y,X=X,phiLags=phiLags,type = 'Poi',method='FS',residuals='Pearson',maxit=100)
#   forecast(mod,n.ahead=h,newdata=X[1:h,,drop=F],newoffset=rep(0,h))$mu
# }
# 
# for(j in 1:nrow(X)){
#   print(j)
#   dump=glarmafc(X$train[[j]],h=h)
# }
# Xglarma=X%>%
#   transmute(glarmaf=map(train,~glarmafc(.,h=h)),
#             glarma_mase=map_dbl(glarmaf,function(a)mean(abs(a))/b[1,'MAE']))

Xfc=bind_cols(Xets,Xstl,Xcros,Xnaive,Xsnaive,Xmean,X[,c('ts','test')])%>%
  mutate(a0_mase=map2_dbl(test,snaive_acc,function(a,b)mean(abs(a))/b[1,'MAE']))%>%
  transmute(glarmaf=map(train,~glarmafc(.,h=h)),
            glarma_mase=map_dbl(glarmaf,function(a)mean(abs(a))/b[1,'MAE']))%>%
  select(-test)

Xass=Xfc%>%
  mutate(naive_by_mase=(pmin(naive_mase,snaive_mase,a0_mase,mean_mase)<=pmin(cros_mase,ets_mase,stl_mase)),
         gain_mase=pmin(naive_mase,snaive_mase,a0_mase,mean_mase)-pmin(cros_mase,ets_mase,stl_mase))%>%
  select(ts,naive_by_mase,gain_mase)


Y=X%>%
  inner_join(Xfeatures)%>%
  inner_join(Xfc)%>%
  inner_join(Xass)%>%
  filter(p0<1)

save(Y,Xass,Xfc,X,file='modelability/experiments/exp2/XandY.RData')


gen_plot=function(dat,var1,var2){
  g1=ggplot(dat,aes(x=!!sym(var1),y=!!sym(var2),col=naive_by_mase))+theme(legend.position = 'na')+scale_y_continuous(limits=c(0,1))+scale_x_continuous(limits=c(0,1))
  if(var1==var2)return(g1)
  # g1+geom_point(alpha=0.5)
  g1+geom_point(alpha=0.2)+stat_ellipse()
}

myplot=function(.ts){
  # browser()
  dat=Y%>%
    filter(ts==.ts)
  autoplot(cbind(dat$train[[1]],
                 dat$test[[1]],
                 dat$etsf[[1]]$mean,
                 dat$stlf[[1]]$mean,
                 dat$crosf[[1]]$mean,
                 dat$naivef[[1]]$mean,
                 dat$snaivef[[1]]$mean,
                 dat$meanf[[1]]$mean))+
    annotate(geom='text',label=sprintf('ets%.3f\nstl%.3f\ncros%.3f\nnaive%.3f\nsnaive%.3f\nmean%.3f\na0%.3f',
                           dat$ets_mase,dat$stl_mase,dat$cros_mase,dat$naive_mase,dat$snaive_mase,dat$mean_mase,dat$a0_mase),x=Inf,y=Inf,vjust=1, hjust=1)+
    ylab('')+scale_y_continuous(breaks=0:15)
}


plots=list()
var_list=c('permu_en','trendS','p0')
ii=1
for(i in var_list){
  for(j in var_list){
    plots[[ii]]=gen_plot(Y,i,j)
    ii=ii+1
  }
}

patchwork::wrap_plots(plots,ncol = 3,nrow=3)

Y%>%
  filter(!naive_by_mase)%>%
  select(ts,ends_with('mase'),-gain_mase,-naive_by_mase)%>%
  tidyr::gather(var,val,-ts)%>%
  group_by(ts)%>%
  filter(val==min(val))%>%
  ungroup%>%
  count(var,sort=T)


raw_features=Y%>%
  select(spectral_en,sample_en,permu_en,trendS,seasonalS,p0,lumpiness,stability,in_naive_rmse,in_snaive_rmse,in_sd,in_0_sd)
yy=Y%>%select(naive_by_mase)
fn_list=list(function(x,y)x/y,function(x,y)x/(1-y))


z=expand.grid(x=seq_along(raw_features),
            f=seq_along(fn_list),
            y=seq_along(raw_features))%>%
  as_tibble%>%
  mutate(ft=purrr::pmap(list(.x=x,.f=f,.y=y),function(.x,.f,.y)setNames(fn_list[[.f]](raw_features[,.x],raw_features[,.y]),paste(colnames(raw_features)[.x],.f,colnames(raw_features)[.y],sep='_'))))%>%
  {bind_cols(.$ft)}%>%
  bind_cols(raw_features,yy)%>%
  as_tibble
  
z2=sapply(z,var,na.rm=T)

library(varrank)
vr=varrank(data.df = z[,which(z2>0)], method = "estevez", variable.important = "naive_by_mase", discretization.method = "sturges", algorithm = "forward", scheme="mid", n.var=5,verbose = T)
summary(vr)

cor(z[,which(z2>0)]%>%select(matches('.*_[0-9]_.*')),z[,'gain_mase'],use='pair')



## I want: low metric number = high modelability (naive_by_mase=FALSE)
## permu/(1-p0) and permu/(1-stability) seem to be the best
Y%>%
  arrange(per)%>%
  select(ts,per,naive_by_mase,naive_by_rmse,permu_en,p0)

## do machine learning way
library(party)
mytree=ctree(factor(naive_by_mase)~.,data=z)
plot(mytree)

## let's try to optimize the power (p) in permu/(1-p0^p)
optim(0.1,function(p)summary(glm(naive_by_mase~I(permu_en/(1-p0^p)),data=Y,family='binomial'))$aic,lower=0,upper=10,method='Brent')

## so permu/(1-p0^2) works quite well for metric>8.7, but why it doesn't work as well when metric<8.7?
Y%>%
  arrange(desc(per))%>%
  filter(per<=8.749)%>%
  select(ts,per,naive_by_mase,naive_by_rmse,permu_en,p0)%>%
  head(20)


myplot(21063094) ## naive not far off, ets = flat
myplot(21052133) ## ets = flat
myplot(21058985)
myplot(21036047)
myplot(21056514)

