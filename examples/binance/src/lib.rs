use anyhow::Result;
use blocksense_sdk::{
    oracle::{DataFeedResult, DataFeedResultValue, Payload, Settings},
    oracle_component,
    spin::http::{send, Method, Request, Response},
};
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use url::Url;

// Struct to hold configuration for which trading pair to fetch
#[derive(Default, Debug, Clone, PartialEq, Deserialize)]
pub struct BinanceResource {
    pub symbol: String,  // Trading pair symbol e.g., "BTCUSDT"
}

// Struct to hold candlestick (kline) data from Binance
// Each candlestick contains OHLCV data for a specific time period
#[derive(Debug, Serialize, Deserialize)]
struct PriceData {
    timestamp: DateTime<Utc>,  // Opening time of the candlestick
    open: f64,    // Opening price
    high: f64,    // Highest price during the period
    low: f64,     // Lowest price during the period
    close: f64,   // Closing price
    volume: f64,  // Trading volume during the period
}

// Function to fetch candlestick data from Binance API
// Parameters:
// - symbol: Trading pair (e.g., "BTCUSDT")
// - interval: Candlestick interval (e.g., "1h", "1d")
// - limit: Number of candlesticks to fetch
async fn fetch_binance_prices(symbol: &str, interval: &str, limit: u32) -> Result<Vec<PriceData>> {
    // Binance klines/candlestick API endpoint:
    // https://api.binance.com/api/v3/klines
    // Parameters:
    // - symbol: Trading pair
    // - interval: Candlestick interval
    // - limit: Number of candlesticks (optional)
    let url = Url::parse_with_params(
        "https://api.binance.com/api/v3/klines",
        &[
            ("symbol", symbol),
            ("interval", interval),
            ("limit", &limit.to_string()),
        ],
    )?;

    // Build HTTP GET request
    let mut req = Request::builder();
    req.method(Method::Get);
    req.uri(url);
    req.header("Accept", "application/json");
    
    let req = req.build();
    let resp: Response = send(req).await?;
    let body = resp.into_body();
    let string = String::from_utf8(body)?;
    
    println!("Binance Response for {} = `{}`", symbol, &string);
    
    // Binance returns klines data as an array of arrays:
    // [
    //   [
    //     1499040000000,      // Open time [0]
    //     "0.01634790",       // Open [1]
    //     "0.80000000",       // High [2]
    //     "0.01575800",       // Low [3]
    //     "0.01577100",       // Close [4]
    //     "148976.11427815",  // Volume [5]
    //     ... // Additional fields we don't use
    //   ]
    // ]
    let response: Vec<Vec<serde_json::Value>> = serde_json::from_str(&string)?;
    
    let mut price_data = Vec::new();
    for kline in response {
        // Convert timestamp from milliseconds to seconds and create DateTime
        let timestamp = DateTime::from_timestamp(
            kline[0].as_i64().unwrap() / 1000,
            0
        ).unwrap();

        // Parse each field from the kline array
        price_data.push(PriceData {
            timestamp,
            open: kline[1].as_str().unwrap().parse()?,   // Parse string to f64
            high: kline[2].as_str().unwrap().parse()?,
            low: kline[3].as_str().unwrap().parse()?,
            close: kline[4].as_str().unwrap().parse()?,
            volume: kline[5].as_str().unwrap().parse()?,
        });
    }

    Ok(price_data)
}

#[oracle_component]
async fn oracle_request(settings: Settings) -> Result<Payload> {
    let mut resources: HashMap<String, BinanceResource> = HashMap::new();
    let mut symbols: Vec<String> = vec![];
    
    // Parse configuration for each data feed
    for feed in settings.data_feeds.iter() {
        let data: BinanceResource = serde_json::from_str(&feed.data)?;
        resources.insert(feed.id.clone(), data.clone());
        symbols.push(data.symbol);
    }

    let mut payload: Payload = Payload::new();
    
    // Fetch and process data for each configured trading pair
    for (feed_id, data) in resources.iter() {
        // Fetch 1-hour candlestick, limit=1 means only the most recent candle
        match fetch_binance_prices(&data.symbol, "1h", 1).await {
            Ok(prices) => {
                if let Some(latest_price) = prices.first() {
                    // Use the closing price as the current price
                    // You could also use other values like:
                    // - latest_price.open for opening price
                    // - latest_price.high for period high
                    // - latest_price.low for period low
                    // - (latest_price.high + latest_price.low) / 2.0 for midpoint
                    payload.values.push(DataFeedResult {
                        id: feed_id.clone(),
                        value: DataFeedResultValue::Numerical(latest_price.close),
                    });
                } else {
                    payload.values.push(DataFeedResult {
                        id: feed_id.clone(),
                        value: DataFeedResultValue::Error(
                            format!("No price data available for {}", data.symbol)
                        ),
                    });
                }
            },
            Err(e) => {
                payload.values.push(DataFeedResult {
                    id: feed_id.clone(),
                    value: DataFeedResultValue::Error(
                        format!("Failed to fetch price data for {}: {}", data.symbol, e)
                    ),
                });
            }
        }
    }
    
    Ok(payload)
}