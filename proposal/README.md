# Monash PhD Research Proposal

# Improving Intermittent Time Series Forecast by Pooling Information Across Groups

Forecasting intermittent time series has been challenging. Classical methods such as exponential smoothing or ARIMA models do not handle the count nature of the series, and the consequential heteroscedasticity, while dedicated models such as Croston's (1972) method often struggle to produce forecast that are better than simple methods (e.g. using historical means, or a random walk model). However, we observe that intermittent time series often (though not always) arise as part of a larger group of time series. For example, a retailer might wish to forecast the demand of each of their products at each of their store locations. Unless the product is a fast-moving item (e.g. milk), these series will typically be intermittent, but there will be many of them. Furthermore, while these base series often appear erratic, their aggregate (e.g., the demand of a product at the national level) often display sufficiently strong signal to develop good forecasting models. We believe we can exploit the hierarchical nature of this problem in order to create better forecasts.

We will focus our research in 3 areas:

## 1. Forecastibility

### Current state of research
In the field of supply chain management, XYZ analysis attempts to quantify the forecastability of a time series by its coefficient of variation. More generally, Shannon entropy (1949) has been applied to an estimate of the spectral density of a time series as a measure of its forecastability. Sample Entropy (Richman et al. 2000) has also been proposed as a measure of the complexity of a time series without the need to estimate either the spectral density.

### Knowledge gap and research proposal
It seems unlikely that spectral or autocovariance-based statistics can successfully measure forecastability in the intermittent setting, given that the autocovariance function may not capture much useful temporal information of a time series with many zeros. The Sample Entropy is based on the similarity between the time series with its lagged value. In a time series with many zeros, this calculated statistic might be distorted by the high number of matches between zeros.

We intend to modify the Sample Entropy, possibly by giving special treatment to the zeros. The usefulness of any proposed statistics can be measured by an experiment in which we artificially generate intermittent series and measure the forecast performance of various methods.

In the context of hierarchical/grouped time series, we also seek to develop a measure of forecastability of a series (possibly some sort of conditional entropy) given other series in the hierarchy. Such a measure has two utilities: 1. it can be used as a screening test to see if it is worth modelling the time series using non-trivial methods (e.g. historical mean, random walk); 2. it can be used to select which level of the hierarchy should be used to facilitate the forecast of the base series (see research area 3).

## 2. Reconciliation of discrete time series

### Current state of research
Hyndman et. al. (2011) and Wickramasuriya et. al. (2019) proposed an optimization method to reconcile the forecasts in the hierarchy, and these methods also improve the forecasts. Athanasopoulos et. al. (2016) applied the same method but to temporal hierarchies instead and also reported a gain in forecast accuracy.

An alternative method of exploiting the temporal aggregate for forecasting, especially with intermittent series, is proposed by Petropoulos & Kourentzes (2015), where they use exponential smoothing to forecast at the aggregated level, before decomposing it back to the base level.

Recently, Gamakumara et al (2018) have proposed an approach to reconciling forecast distributions, but only discuss continuous probability distributions.

### Knowledge gap and research proposal
These current methods do not intrinsically align with the discrete nature of the time series. That is, the forecast distribution of integer-valued data must be discrete, and the reconciliation step might render it non-integer. We seek to develop methods which respect the discrete sample space of the data.

One method we can use is integer programming, which is an extension of the GTOP method of van Erven & Cugliari (2015) with the addition of an integer constraint.

Another approach might be exploit the fact that a discrete random variable often has a corresponding counter-part in their aggregated form (e.g. Bernoulli --> Binomial, Geometric --> Negative binomial), and in the opposite direction, given the aggregated value, the component value often follows some well-studied distribution as well (e.g. if X, Y are Poisson r.v., X|X+Y is binomial). If we can define a suitable set of distributions to characterize the hierarchy, we can possibly develop some form of parametric reconciliation method.

## 3. Improving Intermittent Time Series Forecast by Pooling Information Across Groups

### Current state of research
There has been much research in modelling intermittent time series.

#### Croston's method

Croston et. al. (1972) proposed an innovative method to forecast intermittent time series. Specifically, the raw series is decomposed into two time series: that of the non-zero observations, and the time between successive non-zero observations. Each of these series contains only positive values, thus potentially allowing standard forecasting methods to work. Then the  forecasts from both constructed time series are recombined to produce forecasts on the original time series. Since Croston, several variants have been proposed including Syntetos & Boylan (2001) and Shenstone and Hyndman (2005).

#### INAR and related models
INAR models were proposed by McKenzie (1985) and Al-Osh and Alzaid (1987), where they used the thinning operator (Steutel and van Harn 1979) as the discrete analogue of the autoregressive coefficient in the continuous case. This type of model has two essential components --- the distribution of the innovation process, and the thinning operator --- and they have been extensively researched to cover various cases (innovation distribution: Poisson, geometric, negative binomial, binomial, generalized Poisson, truncated Poisson, zero-modified Poisson, double Poisson; thinning operator: binomial, negative binomial, generalized negative-binomial, dependent Bernoulli, mixture; References are numerous but omitted for space consideration). McKenzie (1988) and Al-Osh and Alzaid (1987) also developed the MA (and thus ARMA) equivalent, while Nastic et. al. (2016) developed the bivariate counterpart. These models are typically estimated with Yule-Walker, conditional least squares, or if tractable, conditional maximum likelihood. Bourguignon and Vasconcellos (2015) developed an estimator based on the second order difference which is computationally more tractable than the maximum likelihood counterpart while being more efficient (and less biased) than the Yule-Walker and least squares counterpart. Seasonal models were tackled in McKenzie (1988) by using sinusoidals, while Bourguignon (2015) developed seasonal equations based on the seasonal lag.

#### GLM-type model
While INAR-type models handle the discrete nature at the observation level, GLM-type models build on top of the (very mature) GLM framework, and push the modelling to the parameter (linear predictor) level. INGARCH (Ferland et al., 2006) is an early example which deals with the Poisson case, where the intensity parameter is modelled as a linear combination of regressors and the past intensity value. This model has since been extended to cover other discrete distributions. Another model of this type is GLARMA (Dunsmuir and Scott 2015), where they manage to specify a full ARMA process in the 'predictive residuals' (itself a function of past observations --- hence they call it an observation driven model, as opposed to parameter driven) on the linear predictor level. Since these models are essentially GLMs, parameters can be estimated using likelihood based methods. The greatest advantage of these type of models (over INAR type model) is that it opens the door for the inclusion of covariates.

#### Gaussian-Cox process
A Cox process is an inhomogeneous Poisson process where the intensity (rate parameter) is itself a stochastic process. A Gaussian-Cox process is one where that stochastic process is Gaussian. Its relevance to intermittent series forecast is that the Cox (Poisson) component can be used to model the base level time series of counts, with the intensity parameter modelled at the aggregated level using classical time series methods (which naturally produces a Gaussian process). While these methods often result in intractable likelihood models (Adams et. al. 2009), advances in simulation based methods (Teng et. al. 2017) can alleviate the problem at the expense of a heavier computation burden.

Berry & West (2019) used a similar strategy, where they (as an example) forecasted at the aggregated level, and then feed this stochastic forecast into the various base level forecasts as part of the intensity model.

### Knowledge gap and research proposal

INAR-type models are fairly limited as they don't allow for covariates. However, the thinning operator is an innovative breakthrough, and it has some resemblance to the top-down approach where we break/disaggregate (thin) the top level forecast into the base level ones.

A more promising approach is the GLM type model, or the Gaussian-Cox process, where the intensity parameters can be modelled/informed by the aggregate level forecast.

The model of Berry & West (2019) is in spirit very similar to this approach, but we see three (possibly incompatible) directions of further development.

* Computation: Berry & West (2019) adopted a two-stage iterative computation approach --- one sends the aggregated forecast down to facilitate forecasting at the base level, and another sends the information back to update the aggregated level model. However, in our experience, in the intermittent setting, bottom level models do not usually help higher level models. In fact, Table 2 of Wickramasuriya et. al. (2019) reveals the same insight. Therefore, we propose pushing the separation of computation even further. First, forecast at the aggregated level for the entire time horizon. Next, we send each of the forecast distributions to the base level models for base level forecasting. The advantage of this is that we eliminate the back-and-forth communication step, which is often the most time consuming component in any distributed computing system. The cost is then the potential decrease in forecast accuracy at the aggregate level, which we deem to be minimal.
* Utilisation of hierarchical information: Instead of pursuing further computational gains, we can choose to model the entire group together which will enable more sophisticated sharing of information. For example, in a two level hierarchy, conditioned on the top level forecast, we can model the base level forecasts as a multinomial process (i.e. how to best split the aggregate forecast across the base series). This will improve or even enforce aggregation-consistency. Or, in a multi-level hierarchy, all upper level forecasts can feed into the base level by specifying some form of nested random effect structure.
* Utilising temporal correlation: In Berry & West (2019) all temporal correlations at the base level series are contained in the (known) evolution matrix for the state vector (their G matrix). Instead of this setup, we can potentially follow Croston and incorporate the information from past inter-demand time intervals and demand sizes.

