library(zoo)
library(fpp)
library(nortest)
library(lmtest)



# Task 1: Obtain the ts
df = read.csv('Uzb_monthly_inflation.csv')
head(df)
df$Date = as.yearmon(df$Date, format = "%Y-%m")
ts_data = zoo(df$Inflation.Change, order.by = df$Date)
ts_data = ts(coredata(ts_data), start = c(2010, 1), frequency = 12)
print(ts_data)
plot(ts_data, main = "Monthly Inflation Change in Uzb", ylab = "Inflation Change", xlab = "Time")



# Task 2: Detrend the series
# Use a linear model to find the trend, then subtract it from the ts
trend <- lm(ts_data ~ time(ts_data))
detrended_series <- ts_data - fitted(trend)
plot(detrended_series, main = "Detrended Series", ylab = "Residuals", xlab = "Time")



# Task 3: Create and plot ACF & PACF
acf(detrended_series, main = 'ACF of the Time Series') # Result: Quickly degrading values => probably stationary
pacf(detrended_series, main = 'PACF of the Time Series')



# Task 4: Check whether serially auto-correlated. Compare to task (iii)
Box.test(detrended_series, type = 'Ljung-Box')
# Result: p-value = 7.772e-14 => significant autocorrelation



# Task 5: Check for stationarity. Compare to task (iii)
# Test 1: Augmented Dickey-Fuller Test (ADF)
adf.test(detrended_series)
# Result: p-value = 0.01 => reject null hypot. => stationary

# Test 2: Kwiatkowski-Phillios-Schmidt-Shin (KPSS)
kpss.test(detrended_series)
# Result: p-value = 0.06048 > 0.05 => cannot reject H0 => stationary



# Task 6: Normality test
# Test 1: Lilliefors (Kolmogoros-Smirnov)
lillie.test(coredata(detrended_series))
# Result: p-value = 2.975e-05 => reject H0 => Not a normal distribution

# Test 2: Anderson-Darling
ad.test(as.numeric(coredata(detrended_series)))
# Result: p-value = 4.002e-10 => reject H0 => Not a normal distribution

# Test 3: Shapiro-Francia
sf.test(detrended_series)
# Result: p-value = 1.032e-05 => reject H0 => Not a normal distribution



# Task 7: Fit an ARMA model & determine the best lag order
# Accounting for seasonality (Appropriate ARMA model (SARIMA))
acf(detrended_series, lag.max = 12, type = 'correlation')
pacf(detrended_series, lag.max = 12)
automatic = auto.arima(detrended_series)
summary(automatic)

sarima_model = arima(detrended_series,
                      order = c(1, 0, 2),
                      seasonal = list(order = c(0, 1, 2), period = 12))
summary(sarima_model)
# The residuals should behave like white noise. Let's check that:
checkresiduals(sarima_model)
shapiro.test(residuals(sarima_model)) # p = 1.277e-15 => reject H0 => not normal distribution
bptest(residuals(sarima_model) ~ fitted(sarima_model)) # p = 0.3843 = > cannot reject H0 => heteroscedasticity
Box.test(residuals(sarima_model), lag = 12, type = "Ljung-Box") # p = 0.7837 => cannot reject H0 => no signif. autocorrelation
mean(residuals(sarima_model)) # = -0.006575348, i.e., close enough to 0
# Conclusion: the residuals most likely behave like white noise



# Task 8: Coefficients, equation, 1-step forecast for ARMA
# My current ARMA model looks like: ARIMA(p=1, d=0, q=2)(P=0, D=1, Q=2)[s=12], where
# p - number of autoregressive (AR) terms
# d - the differencing to make the ts stationary
# q - number of moving average (MA) terms
# P - number of seasonal autoregressive (AR) terms
# D - number of seasonal differencing to make the ts stationary
# Q - number of seasonal moving average (MA) terms
# s - the seasonal period (i.e., 12 months in a year)

# Forecasting
forecast(sarima_model, h=1)


# Task 9: Model conditions:
# residual mean E[e] = 0, 
# finite & constant variance = sigma^2, 
# autocovariance E[e, e] = 0




