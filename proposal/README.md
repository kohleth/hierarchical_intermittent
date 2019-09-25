# Monash PhD Research Proposal

# Improving Intermittent Time Series Forecast by Pooling Information Across Groups

Forecasting intermittent time series has been challenging. Classical methods such as exponential smoothing or ARIMA models do not handle the count nature of the series, and the consequential heteroscedasicity, while dedicated models such as Croston's (1972) method often struggle to produce forecast that are better than simple methods (e.g. using historical means, or a random walk model). However, we observe that intermittent time series often (though not always) arise as part of a larger group of time series. For example, a retailer might wish to forecast the demand of each of their products at each of their store locations. Unless the product is a fast-moving item (e.g. milk), these series will typically be intermittent, but there will be many of them. Furthermore, while these base series often appear erratic, their aggregate (e.g., the demand of a product at the national level) often display sufficiently strong signal to develop good forecasting models. We believe we can exploit the hierarchical nature of this problem in order to create better forecasts.

We will focus our research in 3 areas:

## 1. Forecastibility

### Current state of research
In the field of supply chain management, there is XYZ analysis which attempts to quantify the forecastability of a times series by its coefficient of variation. In a more general setting, Shannon entropy (1949) has been used to measure the information content associated with an event. In the time series setting, it has been applied to (the random variable implied by the) spectral density of the autocovariance function, as a measure of forecastibility. Various non-/parametric methods as been proposed to estimate the said density. Sample Entropy (Richman et al. 2000) has also been proposed as a measure of forecastibility without the need to estimate either the autocovariance function or its spectral density. 

### Knowledge gap and research proposal
It is unlikely that autocovariance-based forecastility statistics can successfully measure forecastibility in the intermittent setting, given that the autocovariance function will won't capture much (if any) temporal information of a time series with many zeros. Sample Entropy is based on the similarity between the time series with its lagged value. In a time series with many zero, this calculated statistic might be distorted by the high number of matches between zeros -- which renders it less useful (while being correct). 

We intend to modify the Sample Entropy, possibly by giving special treatment to the zeros. The usefulness of any proposed statistics can be measured by experiment in which we artificially generate intermittent series and measure the forecast performance of various methods.

In the context of hierarchical / group time series, we seek to develop a measure of forecastibility of a series  (possibly some sort of conditional entropy) given other series in its hierarchy. Such measure has two utilities: 1. it can be used as a screening test to see if it is worth modelling the time seires using non-trivial methods (e.g. historical mean, random walk) 2. it can be used to select which level of the hierarchy should be used to facilitate the forecast of the base series (see research area 3).

## 2. Reconciliation of discrete time series

### Current state of research
Hyndman et. al. (2011) and Wickramasuriya et. al. (2019) proposed regression based method to reconcile the forecasts in the hierarchy, and these methods in theory also improve the forecast. Athanasopolous et. al. (2016) applied the same method but to temporal hierarchy (aggregate) instead and also reported gain in forecast accuracy. 

An alternative method of exploting the temporal aggregate for forecasting, especially with intermittent series, is proposed by Petropoulos & Kourentzes (2015), where they use exponential smoothing to forecast at the aggregated level, before decomposing it back to the base level.

### Knowledge gap and research proposal
These current methods do not intrinsically align with the discrete nature of the time series. That is, even if the base series forecast is integer-valued, the reconciliation step might render it non-integer. Depending of the usage, this might not be a problem, but in cases where the integer value constraint is important, we seek to develop methods which respect this constraint. 

One method we can use is integer programming, which is an extension of the GTOP method of van Erven & Cugliari (2015) with the addition of an integer constraint. 

Another approach might be exploit the fact that most (all?) discrete random variable has a corresponding counter-part in their aggregated form (e.g. Bernoulli --> Binomial, Geomtric --> Negative bionomial), and in the opposite direction, given the aggregated value, the component value often folows some known distribution as well (e.g. if X, Y are Poisson r.v., X|X+Y is binomial). If we can define a suitable set of distributions to characterize the hierarchy, we can possibly develop some form of parametric reconciliation method.


## 3. Improving Intermittent Time Series Forecast by Pooling Information Across Groups

### Current state of research
There has been many research in modelling intermittent time series. Croston et. al. (1972) proposed splitting the series into its non-zero component, and the inter-event time gap, and to model them separately. 

### Knowledge gap and research proposal


#### Croston's method

Croston et. al. (1972) proposed an innovative method to forecast intermittent time series. Specifically, the raw series is decomposed into two time series: that of the non-zero observations, and the time between successive non-zero observations. Each of these series contains only positive values, thus potentially allowing standard forecasting methods to work. Then the  forecasts from both constructed time series are recombined to produce forecasts on the original time series. Since Croston, several variants have been proposed including Syntetos & Boylan (2001) and Shenstone and Hyndman (2005).

#### INGARCH

Another approach to this problem is the INGARCH model (Ferland et al., 2006). Noting that most intermittent series are time series of counts, one can use a generalized linear model (Poisson or negative binomial family) to model such data. The GLM framework opens the door for regression against covariates, although in the time series setting these covariates are typically lagged versions of the observation or parameter, and ARMA type error.

#### INAR and related models

#### GLARMA models

#### Non-Gaussian state space models

#### Gaussian-Cox process
A Cox process is an inhomogenous Poisson process where the intensity (rate parameter) is itself a stochastic process. A Gaussian-Cox process one where that stochastic process is gaussian. Its relevance to intermittent series forecast is that, the Cox (Poisson) component can be used to model the base level time series of count, with the intensity parameter modelled at the aggregated level using classical time series methods (which naturally produces a gaussian process). While these methods often result in in-tractable likelihood models (Adams et. al. 2009), advances in simulation base method (Teng et. al. 2017) can alleviate the problem at the expense of a heavier computation burden. 

Berry & West (2019) performed similar strategy, where they (as an example) forecasted at the aggregated level, and then feed this stochastic forecast into the various base level forecast as part of the intensity model. 



#### Improving intermittent time series forecast by pooling information across groups (2 papers expected)
We can think of three broad ways of tackling this problem. The first two will probably fail but since this is research we should try all and fail fast.

3. Gaussian-Cox process -- we see this as an amalgamation of hierarchical forecasting and INGARCH. Reiterating the paragraph above, suppose we can produce reasonably accurate forecast at the aggregate level using classical methods (producing a gaussian estimate), this can feed into the intensity parameter of the possion distribution at the base level. The difficulty of doing this is in balancing the contribution of this information with that from the series itself (i.e. the lagged observation). This might mean we need to introduce additional weight parameter. The computation aspect can be handle by bayesian computation. The model of Berry & West (2019) is in spirit very similar to this approach. But we see 3 (non-compatible) directions of further development. 
    + Computation: Berry & West (2019) adopted a two-stage iterative computation approach -- one sends the aggregated forecast down to facilitate forecasting at the base level, and another sends the information back to update the aggregated level model. However, in our experience, in the intermittent setting, bottom level models doesn't usually help higher level models. In fact, table 2 of Wickramasuriya et. al. (2019) reveals the same insights. Therefore, we propose pushing the separation of computation even further -- First, forecast at the aggregated level for the entire time horizon. Next, we send each of the forecast (distribution) to the base level models for base level forecast. The advantage of this is that we eliminated the back-and-forth communication step, which is often the most time consuming component in any distributed computing system. The cost is then the potential decrease in forecast accuracy at the aggregate level, which we deem to be minimal.
    + Utilisation of hierarchical information: Instead of pursuing further computation gain, we can choose to model the entire group together which will enable more sophisticated sharing of information. For example, in a two level hierarchy, conditioned on the top level forecast, we can model the base level forecasts as a multinomial process (i.e. how to best split the aggregate forecast across the base series). This will improve or even enfore aggregation-consistency. Or, in a multi-level hierarchy, all upper level forecasts can feed into the base level by specifying some form of nested random effect structure.
    + Utilising temporal correlation: In Berry & West (2019) all temporal correlation at the base level series is contained by the (known) evolution matrix for the state vector (their G matrix). Instead of this setup, we can potentially follow Croston and incorporate the information from past inter-demand time interval and demand size.

We shall point out that in this research our primary concern is in improving forecast accuracy, not reconciliating forecast. Therefore, we will venture beyond the space of aggregate-consistent forecast methods. (If aggregate-consistency is critical, one can always run the standard hts reconciliation step at the end to adjust the forecasts). Since we are not reconciliating forecast, we do not necessarily need forecasts from all aggregation level in the model. This opens up a further research question -- can we only consider a subset of all aggregation level when pooling information? If so, how can we determine these levels?