library(dplyr)
library(tidyr)
library(readr)
library(foreach)
library(doParallel)
library(itertools)
library(pracma)
source('modelability/experiments/exp5/utils.R')
the_dir=rstudioapi::askForPassword(prompt = 'the_dir')

X0=read_csv(file.path(the_dir,'all_ts.csv'),col_types = cols(i=col_integer(),
                                                             j=col_integer(),
                                                             t=col_integer(),
                                                             y=col_double()))

X=X0%>%
  nest(t,y,.key='ts')%>%
  mutate(ts=purrr::map(ts,~ts(.$y,frequency=52)))

saveRDS(X,file.path(the_dir,'all_ts_tibble.rds'))



## FORECAST PERFORMANCE---------------------------------------------------------------- 
cl=makeCluster(15)
registerDoParallel(cl)

system.time({ets_fc_er=foreach(x=X$ts,.packages=c('forecast'))%dopar%{
    tsCV(x,forecastfunction=function(.x,h)forecast(ets(.x,model='ZZN'),h=h),h=1,initial=52)
}})
# F16s: makeCluster(15)
# user   system  elapsed 
# 982.90   473.65 34045.91 
saveRDS(etc_fc_er,file.path(the_dir,'ets_fc_er.rds'))

system.time({cros_fc_er=foreach(x=X$ts,.packages=c('forecast'))%dopar%{
  tsCV(pmax(0,x),forecastfunction=mycroston,h=1,initial=52)
}})
# F16s: makeCluster(15)
# user   system  elapsed 
# 1003.246  227.580 9986.057 

saveRDS(cros_fc_er,file.path(the_dir,'cros_fc_er.rds'))


system.time({naive_fc_er=foreach(x=X$ts,.packages=c('forecast'))%dopar%{
  tsCV(x,forecastfunction=naive,h=1,initial=52)
}
})
# F16s: makeCluster(15)
# user   system  elapsed 
# 745.282  195.397 7290.660 

saveRDS(naive_fc_er,file.path(the_dir,'naive_fc_er.rds'))


system.time({snaive_fc_er=foreach(x=X$ts,.packages=c('forecast'))%dopar%{
  tsCV(x,forecastfunction=snaive,h=1,initial=52)
}
})

# F16s: makeCluster(15)
# user   system  elapsed 
# 894.474  187.297 7057.967 

saveRDS(snaive_fc_er,file.path(the_dir,'snaive_fc_er.rds'))


system.time({mean_fc_er=foreach(x=X$ts,.packages=c('forecast'))%dopar%{
  tsCV(x,forecastfunction=meanf,h=1,initial=52)
}})

# F16s: makeCluster(15)
# user   system  elapsed 
# 775.468  148.581 4729.280 

saveRDS(mean_fc_er,file.path(the_dir,'mean_fc_er.rds'))


stopCluster(cl)



X=readRDS(file.path(the_dir,'all_ts_tibble.rds'))
X$ets_fc_er=readRDS(file.path(the_dir,'ets_fc_er.rds'))
X$cros_fc_er=readRDS(file.path(the_dir,'cros_fc_er.rds'))
X$naive_fc_er=readRDS(file.path(the_dir,'naive_fc_er.rds'))
X$snaive_fc_er=readRDS(file.path(the_dir,'snaive_fc_er.rds'))
X$mean_fc_er=readRDS(file.apth(the_dir,'mean_fc_er.rds'))

X=X%>%
  mutate(naive_rmse=purrr:::map_dbl(naive_fc_er,~sqrt(mean(.^2,na.rm=T))),
         naive_srmse=1,
         ets_srmse=purrr:::map_dbl(ets_fc_er,~sqrt(mean(.^2,na.rm=T)))/naive_rmse,
         cros_srmse=purrr::map_dbl(cros_fc_er,~sqrt(mean(.^2,na.rm=T)))/naive_rmse,
         snaive_srmse=purrr:::map_dbl(snaive_fc_er,~sqrt(mean(.^2,na.rm=T)))/naive_rmse,
         mean_srmse=purrr:::map_dbl(mean_fc_er,~sqrt(mean(.^2,na.rm=T)))/naive_rmse
         )

Xfc=X%>%
  mutate(naive_complex_ratio=pmin(naive_srmse,snaive_srmse,mean_srmse,na.rm=T)/pmin(ets_srmse,cros_srmse,na.rm=T))%>%
  mutate(naive_better=naive_complex_ratio<1)%>%
  select(-ts)

# saveRDS(Xfc,file.path(the_dir,'X_with_fc.rds'))

## FEATURES-------------------------------------------------------
cl=makeCluster(15)
registerDoParallel(cl)

X$spectral_en=myfeature(X$ts,tsfeatures::entropy)
X$sample_en=myfeature(X$ts,pracma::sample_entropy)
X$permu_en=myfeature(X$ts,permu_en,'dplyr')
X$lumpiness=myfeature(X$ts,function(x)tsfeatures::lumpiness(x,width=4)) ## monthly window
X$stability=myfeature(X$ts,function(x)tsfeatures::stability(x,width=4)) ## monthly window
X$fc_surprise_dist_5_2_upd_mean=myfeature(X$ts,fc_surprise_dist_upd,.export=c('sb_coarsegrain'))
X$sy_trend_meanYC=myfeature(X$ts,sy_trend_meanYC)

Xfeatures=X%>%
  mutate(p0=purrr::map_dbl(ts,~mean(.==0,na.rm=T)),
         in_sd=purrr::map_dbl(ts,sd),
         in_0fc_rmse=purrr::map_dbl(ts,~sqrt(mean(.^2))),
         spr=spectral_en/(1-p0),
         ser=sample_en/(1-p0),
         per=permu_en/(1-p0))

stopCluster(cl)

saveRDS(Xfeatures%>%select(-ts),file.path(the_dir,'X_with_features.rds'))

## partykit--------------------------------------------------------
X=readRDS(file.path(the_dir,'all_ts_tibble.rds'))
Xfc=readRDS(file.path(the_dir,'X_with_fc.rds'))
Xfeatures=readRDS(file.path(the_dir,'X_with_features.rds'))

Y=X%>%
  inner_join(Xfc)%>%
  inner_join(Xfeatures)%>%
  add_count(naive_better)%>%
  mutate(w=1/n,n=NULL)
  

saveRDS(Y,file.path(the_dir,'Y.rds'))
library(partykit)
mytree=ctree(factor(naive_better)~.,
             data=Y%>%filter(p0<1,is.finite(sample_en))%>%select(naive_better,spectral_en:sy_trend_meanYC),
             na.action=na.omit,
             control=ctree_control(minbucket = 100,
                                   maxdepth=4,
                                   alpha=0.01))

mytree_no_ratio=ctree(factor(naive_better)~.,
             data=Y%>%filter(p0<1,is.finite(sample_en))%>%select(naive_better,spectral_en:permu_en,p0,in_sd,in_0fc_rmse,fc_surprise_dist_5_2_upd_mean,sy_trend_meanYC),
             na.action=na.omit,
             control=ctree_control(minbucket = 100,
                                   maxdepth=4,
                                   alpha=0.01))

plot(mytree,tp_args=list(id=FALSE))
plot(mytree_no_ratio,tp_args=list(id=FALSE))
