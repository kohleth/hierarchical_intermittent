library(forecast)
library(pracma)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)
library(patchwork)

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
  )


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



Xfc=X%>%
  mutate(etsf=map(train,~forecast(ets(.),h=h,PI=FALSE)),
         stlf=map(train,~stlf(.,h=h,s.window='periodic')),
         naivef=map(train,~naive(.,h=h)),
         snaivef=map(train,~snaive(.,h=h)))%>%
  mutate(ets_acc=map2(etsf,test,accuracy),
         stl_acc=map2(stlf,test,accuracy),
         naive_acc=map2(naivef,test,accuracy),
         snaive_acc=map2(snaivef,test,accuracy))%>%
  mutate(ets_rmse=map_dbl(ets_acc,~.[2,'RMSE']),
         stl_rmse=map_dbl(stl_acc,~.[2,'RMSE']),
         naive_rmse=map_dbl(naive_acc,~.[2,'RMSE']),
         snaive_rmse=map_dbl(snaive_acc,~.[2,'RMSE']),
         ets_mase=map_dbl(ets_acc,~.[2,'MASE']),
         stl_mase=map_dbl(stl_acc,~.[2,'MASE']),
         naive_mase=map_dbl(naive_acc,~.[2,'MASE']),
         snaive_mase=map_dbl(snaive_acc,~.[2,'MASE']))%>%
  select(-train,-test)

Xass=Xfc%>%
  mutate(naive_by_mase=(pmin(naive_mase,snaive_mase)<pmin(ets_mase,stl_mase)),
         naive_by_rmse=(pmin(naive_rmse,snaive_rmse)<pmin(ets_rmse,stl_rmse)))%>%
  select(ts,naive_by_mase,naive_by_rmse)


Y=X%>%
  inner_join(Xfeatures)%>%
  inner_join(Xfc)%>%
  inner_join(Xass)

gen_plot=function(dat,var1,var2){
  g1=ggplot(dat,aes(x=!!sym(var1),y=!!sym(var2),col=naive_by_mase))+theme(legend.position = 'na')
  if(var1==var2)return(g1)
  # g1+geom_point(alpha=0.5)
  g1+stat_ellipse()
}


plots=list()
var_list=c('sample_en','permu_en','trendS','actual_p0')
ii=1
for(i in var_list){
  for(j in var_list){
    plots[[ii]]=gen_plot(Z2,i,j)
    ii=ii+1
  }
}

patchwork::wrap_plots(plots,ncol = 4,nrow=4)
