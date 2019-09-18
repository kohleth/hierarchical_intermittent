# Monash PhD Research Proposal

# Improving Intermittent Time Series Forecast by Pooling Information Across Groups

Forecasting intermittent time series has been challenging. Classical methods such as exponential smoothing or ARIMA models do not handle the count nature of the series, and the consequential heteroscedasicity, while dedicated models such as Croston's (1972) method often struggle to produce forecast that are better than simple methods (e.g. using historical means, or a random walk model). However, we observe that intermittent time series often (though not always) arise as part of a larger group of time series. For example, a retailer might wish to forecast the demand of each of their products at each of their store locations. Unless the product is a fast-moving item (e.g. milk), these series will typically be intermittent, but there will be many of them. Furthermore, while these base series often appear erratic, their aggregate (e.g., the demand of a product at the national level) often display sufficiently strong signal to develop good forecasting models. We believe we can exploit the hierarchical nature of this problem in order to create better forecasts.

## Current state of research

Here we summarize the relevant research to date.

#### Croston's method

Croston et. al. (1972) proposed an innovative method to forecast intermittent time series. Specifically, the raw series is decomposed into two time series: that of the non-zero observations, and the time between successive non-zero observations. Each of these series contains only positive values, thus potentially allowing standard forecasting methods to work. Then the  forecasts from both constructed time series are recombined to produce forecasts on the original time series. Since Croston, several variants have been proposed including Syntetos & Boylan (2001) and Shenstone and Hyndman (2005).

#### INGARCH
An example regression approach to this problem is the INGARCH type model (Ferland et. al. 2006). Noting that most often intermittent series are time series of count, one can use generalized linear model (possison or negative binomial family) to model such data. The glm framework opens the door for regression against covariates, although in the time series setting these covariates are typically lagged version of the observation or parameter, and ARMA type error.

#### Hierarchical times series
While Croston's and INGARCH type model attempt to extract as much information from the time series itself, hierarchical time series seek to borrow strength from neighbouring series. Hyndman et. al. (2011) and Wickramasuriya et. al. (2019) proposed regression based method to reconcile the forecasts in the hierarchy, and these methods in theory also improve the forecast. Athanasopolous et. al. (2016) applied the same method but to temporal hierarchy (aggregate) instead and also reported gain in forecast accuracy. 

An alternative method of exploting the temporal aggregate for forecasting, especially with intermittent series, is proposed by Petropoulos & Kourentzes (2015), where they use exponential smoothing to forecast at the aggregated level, before decomposing it back to the base level.

#### Gaussian-Cox process
A Cox process is an inhomogenous Poisson process where the intensity (rate parameter) is itself a stochastic process. A Gaussian-Cox process one where that stochastic process is gaussian. Its relevance to intermittent series forecast is that, the Cox (Poisson) component can be used to model the base level time series of count, with the intensity parameter modelled at the aggregated level using classical time series methods (which naturally produces a gaussian process). While these methods often result in in-tractable likelihood models (Adams et. al. 2009), advances in simulation base method (Teng et. al. 2017) can alleviate the problem at the expense of a heavier computation burden. 

Berry & West (2019) performed similar strategy, where they (as an example) forecasted at the aggregated level, and then feed this stochastic forecast into the various base level forecast as part of the intensity model. 

#### Forecastability
There has been limited research to date on this topic -- at what point (what level of intermittent-ness) do we conclude that  there is just no (non-trivial) way of forecasting the series? 

In the context of choosing between Croston's method and its variant, Syntetos & Boylan (2001), and Kostenkov & Hyndman (2005) came up with guidelines based on the coefficient of variation of the non-zero part of the seires, as well as its inter-event interval. In the field of supply chain management, there is also XYZ analysis which attempts to quantify the forecastability of a times series by its coefficient of variation. With the exception of Petropoulos & Kourentzes (2015), all these attempts only look at the forecastability of the series by itself, instead of in the context of a group of series with shareable information. Therefore, it calls for a deeper investigation.


## Research plan
We believe we can contribute to the body of knkowledge in two areas:

#### Forecastability (1 paper expected)
Essentially, we seek to find ways to determinte whether a time series is forecastable (by non-trivial method). Such rules would be useful in situation where a large number of time series needs to be modelled, since they can be used as a screening test to save model time. 

To achieve this, we plan to adopt an inferential approach. First, we simulate a large number of time series with varying degree of intermittent-ness. Next, for each time series we compute various descriptive statistics, including but not limited to: percentage of 0s, CV, mean inter-event time interval etc. Having done this, we fit naive methods (historical means, random-walk etc.) models as well as croston and ETS to each series and compute their performance. This experiment will hopefully reveal conditions under which sophisticated models are no better than naive methods. If there is clear boundaries perhaps mathematical insights can be extracted. But even if we couldn't achieve this, we can at least come up with simple rule-of-thumbs (perhaps by fitting the experimental data to a decision tree).

In the context of hierarchical forecasting, we can expand the above experiments to include group-related descriptive statistics, as well as hierarchical forecasting methods. We hope that this will reveal the region (in the time series space) whose member are not by themselves (non-trivially) forecasteable, but once information are pooled they become admissable. If we can identify such region, all following research will target its members.

#### Improving intermittent time series forecast by pooling information across groups (2 papers expected)
We can think of three broad ways of tackling this problem. The first two will probably fail but since this is research we should try all and fail fast.

1. Hierarchical croston -- can we pool information in the non-zero demand series and the inter-event time interval series? Natually if we can see the aggregated series peaking, we should expect a higher non-zero demand, and shorter inter-event time interval at the base level.

2. Integer-programming -- instead of using regression to pool information, we use integer programming with a suitable cost function. This will at least respect the count nature of the problem, but it is unclear whether it will actually help the forecast. This is an extension of the GTOP method of van Erven & Cugliari (2015) with the addition of an integer constraint.

3. Gaussian-Cox process -- we see this as an amalgamation of hierarchical forecasting and INGARCH. Reiterating the paragraph above, suppose we can produce reasonably accurate forecast at the aggregate level using classical methods (producing a gaussian estimate), this can feed into the intensity parameter of the possion distribution at the base level. The difficulty of doing this is in balancing the contribution of this information with that from the series itself (i.e. the lagged observation). This might mean we need to introduce additional weight parameter. The computation aspect can be handle by bayesian computation. The model of Berry & West (2019) is in spirit very similar to this approach. But we see 3 (non-compatible) directions of further development. 
    + Computation: Berry & West (2019) adopted a two-stage iterative computation approach -- one sends the aggregated forecast down to facilitate forecasting at the base level, and another sends the information back to update the aggregated level model. However, in our experience, in the intermittent setting, bottom level models doesn't usually help higher level models. In fact, table 2 of Wickramasuriya et. al. (2019) reveals the same insights. Therefore, we propose pushing the separation of computation even further -- First, forecast at the aggregated level for the entire time horizon. Next, we send each of the forecast (distribution) to the base level models for base level forecast. The advantage of this is that we eliminated the back-and-forth communication step, which is often the most time consuming component in any distributed computing system. The cost is then the potential decrease in forecast accuracy at the aggregate level, which we deem to be minimal.
    + Utilisation of hierarchical information: Instead of pursuing further computation gain, we can choose to model the entire group together which will enable more sophisticated sharing of information. For example, in a two level hierarchy, conditioned on the top level forecast, we can model the base level forecasts as a multinomial process (i.e. how to best split the aggregate forecast across the base series). This will improve or even enfore aggregation-consistency. Or, in a multi-level hierarchy, all upper level forecasts can feed into the base level by specifying some form of nested random effect structure.
    + Utilising temporal correlation: In Berry & West (2019) all temporal correlation at the base level series is contained by the (known) evolution matrix for the state vector (their G matrix). Instead of this setup, we can potentially follow Croston and incorporate the information from past inter-demand time interval and demand size.

We shall point out that in this research our primary concern is in improving forecast accuracy, not reconciliating forecast. Therefore, we will venture beyond the space of aggregate-consistent forecast methods. (If aggregate-consistency is critical, one can always run the standard hts reconciliation step at the end to adjust the forecasts). Since we are not reconciliating forecast, we do not necessarily need forecasts from all aggregation level in the model. This opens up a further research question -- can we only consider a subset of all aggregation level when pooling information? If so, how can we determine these levels?