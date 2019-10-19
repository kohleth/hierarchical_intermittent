library(forecast)
library(pracma)
library(Mcomp)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)

ts_list=subset(M3,'quarterly')

ts_c=function(ts1,ts2)ts(c(ts1,ts2),start=start(ts1),frequency=frequency(ts1))

my_transform=function(.x,q){
  combined_ts=ts_c(.x$x,.x$xx)
  ntrain=length(.x$x)
  ntest=length(.x$xx)
  sm=stl(combined_ts,s.window=frequency(combined_ts))
  detrended=combined_ts-sm$time.series[,'trend']
  force0=detrended<quantile(detrended,q)
  if(length(force0)>0)combined_ts[detrended<quantile(detrended,q)]=0
  list(train=head(combined_ts,ntrain),test=tail(combined_ts,ntest))
}

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

pvec=seq(0,0.9,by=0.1)


trans_ts_list=lapply(ts_list,function(dat)lapply(pvec,function(q)my_transform(dat,q)))

train_ts_list=lapply(trans_ts_list,function(.x)lapply(.x,function(.xx).xx$train))
test_ts_list=lapply(trans_ts_list,function(.x)lapply(.x,function(.xx).xx$test))

Z=as_tibble(train_ts_list)%>%
  mutate(p=pvec)%>%
  gather(ts,train,-p)%>%
  inner_join(
    as_tibble(test_ts_list)%>%
      mutate(p=pvec)%>%
      gather(ts,test,-p)
  )%>%
  mutate(spectral_en=map_dbl(train,~try(tsfeatures::entropy(.))),
         sample_en=map_dbl(train,~try(pracma::sample_entropy(.))),
         permu_en=map_dbl(train,~try(permu_en(.))),
         stlf=map(train,~try(tsfeatures::stl_features(.))),
         trendS=map_dbl(stlf,~ifelse(inherits(.,'try-error'),NA,.['trend'])),
         seasonalS=map_dbl(stlf,~ifelse(inherits(.,'try-error'),NA,.['seasonal_strength'])),
         actual_p0=map_dbl(train,~try(mean(.==0))),
         spr=spectral_en/(1-actual_p0),
         ser=sample_en/(1-actual_p0),
         per=permu_en/(1-actual_p0))%>%
  mutate(etsf=map(train,~forecast(ets(.),h=8,PI=FALSE)),
         naivef=map(train,~naive(.,h=8)),
         snaivef=map(train,~snaive(.,h=8)))%>%
  mutate(ets_acc=map2(etsf,test,accuracy),
         naive_acc=map2(naivef,test,accuracy),
         snaive_acc=map2(snaivef,test,accuracy))%>%
  mutate(ets_rmse=map_dbl(ets_acc,~.[2,'RMSE']),
         naive_rmse=map_dbl(naive_acc,~.[2,'RMSE']),
         snaive_rmse=map_dbl(snaive_acc,~.[2,'RMSE']),
         ets_mase=map_dbl(ets_acc,~.[2,'MASE']),
         naive_mase=map_dbl(naive_acc,~.[2,'MASE']),
         snaive_mase=map_dbl(snaive_acc,~.[2,'MASE']))
  
Z2=Z%>%
  mutate(naive_by_mase=(pmin(naive_mase,snaive_mase)<ets_mase),
         naive_by_rmse=(pmin(naive_rmse,snaive_rmse)<ets_rmse))

Z2%>%
  filter(ts=='N0923')%>%
  select(p,train,naive_by_mase,ser)%>%
  mutate(pp=pmap(list(p=p,train=train,naive_by_mase=naive_by_mase,ser=ser),function(p,train,naive_by_mase,ser){
    autoplot(train)+
      ggtitle(sprintf('p=%1.1f | naive=%s| ser=%1.2f',p,naive_by_mase,ser))
  }))%>%
  slice(8)%>%
  pull(pp)
  

Z%>%
  ggplot(aes(x=p,y=se))+
  geom_point()+
  facet_wrap(~ts)


Z%>%
  ggplot(aes(x=p,y=permu_en))+
  geom_point()+
  facet_wrap(~ts)

Z%>%
  ggplot(aes(x=p,y=xe0))+
  geom_point()+
  facet_wrap(~ts)


Z%>%
  ggplot(aes(x=p,y=en))+
  geom_point()+
  facet_wrap(~ts)


Z%>%
  ggplot(aes(x=p,y=r))+
  geom_point()+
  geom_line()+
  facet_wrap(~ts)

Z%>%
  ggplot(aes(x=p,y=rmu))+
  geom_point()+
  geom_line()+
  facet_wrap(~ts)

Z%>%
  ggplot(aes(x=p,y=rp0))+
  geom_point()+
  geom_line()+
  facet_wrap(~ts)


Z%>%
  ggplot(aes(x=p,y=rp0))+
  geom_point()+
  geom_line()+
  facet_wrap(~ts)

Z%>%
  ggplot(aes(x=p,y=rp0v2))+
  geom_point()+
  geom_line()+
  facet_wrap(~ts)

Z%>%
  filter(p==0)%>%
  ggplot(aes(x=t,y=y))+
  geom_line()+
  facet_wrap(~ts,scale='free')

Z%>%
  filter(ts=='N1102')%>%
  mutate(lab=sprintf('%0.2f
                     rxe0: %1.2f=%1.2f/%1.2f 
                     rp0: %1.2f=%1.2f/%1.2f 
                     rp0_mod: %1.2f=%1.2f/%1.2f
                     compS(t/s): %1.2f (%1.2f/%1.2f)',p0,r,se,xe0,rp0,se,-log(p0),se/(1-p0),se,(1-p0),pmax(trendS,seaS),trendS,seaS))%>%
  ggplot(aes(x=t,y=y))+
  geom_point()+
  geom_line()+
  facet_wrap(~lab)

plr=function(ts)mean(ts<0.2*sd(ts))
trans_ts_list_plr=lapply(trans_ts_list,function(dat)sapply(dat,plr))


## for each series, is Pr(m+1 match | m matches) the same as Pr(any random pair match)? 
trans_ts_list_any_pair_match=lapply(trans_ts_list,function(dat)sapply(dat,function(.x)-log(mean(dist(.x)<(0.2*sd(.x))))))

bind_cols(trans_ts_list_se)%>%
  mutate(p=pvec)%>%
  gather(ts,se,-p)%>%
  inner_join(bind_cols(trans_ts_list_any_pair_match)%>%
               mutate(p=pvec)%>%
               gather(ts,p_pmatch,-p))%>%
  ggplot(aes(x=p_pmatch,y=se))+
  geom_point()+
  geom_abline()+
  facet_wrap(~ts)


##
