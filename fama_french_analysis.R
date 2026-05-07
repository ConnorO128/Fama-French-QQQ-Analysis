library(tidyverse)
library(quantmod)
library(PerformanceAnalytics)
library(lubridate)
library(broom)
library(ggplot2)
library(readr)

getSymbols("QQQ", src = "yahoo", from = "2015-01-01")
head(QQQ)

QQQ_monthly <- to.monthly(QQQ, indexAt = "lastof", OHLC = FALSE)

QQQ_returns <- monthlyReturn(Cl(QQQ_monthly))

head(QQQ_returns)

ff_url <- "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip"
download.file(ff_url, "ff.zip", mode = "wb")
unzip("ff.zip")

ff_data <- read_csv(
  "F-F_Research_Data_Factors.csv",
  skip = 3
)

head(ff_data)

colnames(ff_data) <- c(
  "date",
  "Mkt_RF",
  "SMB",
  "HML",
  "RF"
)

head(ff_data)

ff_data$date <- ymd(
  paste0(ff_data$date, "01")
)

head(ff_data)

QQQ_df <- data.frame(
  date = index(QQQ_returns),
  QQQ_Return = coredata(QQQ_returns)
)

head(QQQ_df)

ff_data <- ff_data %>%
  mutate(date = ceiling_date(date, "month") - days(1))

merged_data <- left_join(
  QQQ_df,
  ff_data,
  by = "date"
)

head(merged_data)

merged_data <- merged_data %>%
  drop_na()

merged_data <- merged_data[-1, ]

merged_data <- merged_data %>%
  mutate(
    Mkt_RF = Mkt_RF / 100,
    SMB = SMB / 100,
    HML = HML / 100,
    RF = RF / 100,
    Excess_Return = monthly.returns - RF
  )

head(merged_data)
tail(merged_data)

ff_model <- lm(
  Excess_Return ~ Mkt_RF + SMB + HML,
  data = merged_data
)

summary(ff_model)

ggplot(merged_data, aes(x = date, y = cumprod(1 + monthly.returns))) +
  geom_line() +
  labs(
    title = "Growth of $1 Invested in QQQ",
    y = "Portfolio Value"
  )

ggplot(merged_data, aes(x = HML, y = Excess_Return)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(
    title = "QQQ Excess Returns vs HML"
  )

ggplot(merged_data, aes(x = Mkt_RF, y = Excess_Return)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(
    title = "QQQ Excess Returns vs Market Factor",
    x = "Market Excess Return",
    y = "QQQ Excess Return"
  )

merged_data$Predicted <- predict(ff_model)

ggplot(merged_data, aes(x = Predicted, y = Excess_Return)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0) +
  labs(
    title = "Actual vs Predicted Excess Returns"
  )