use anyhow::Result;
use blocksense_sdk::{
    oracle::{DataFeedResult, DataFeedResultValue, Payload, Settings},
    oracle_component,
    spin::http::{send, Method, Request, Response},
};
use serde::Deserialize;
use url::Url;

#[derive(Deserialize, Debug)]
#[allow(dead_code)]
struct Rate {
    from: String,
    to: String,
    rate: f64,
    timestamp: u64,
}

#[oracle_component]
async fn oracle_request(settings: Settings) -> Result<Payload> {
    let mut payload: Payload = Payload::new();
    // Iterate through all the data feeds that would be served.
    for data_feed in settings.data_feeds.iter() {
        // Feed 222 is string the rest of the feeds are numerical
        if data_feed.id != "222" {
            let url = Url::parse(format!("https://www.revolut.com/api/quote/public/{}", data_feed.data).as_str())?;
            println!("URL - {}", url.as_str());
            let mut req = Request::builder();
            req.method(Method::Get);
            req.uri(url);
            req.header("user-agent", "*/*");
            req.header("Accepts", "application/json");

            let req = req.build();
            // Fetch data for each needed data feed from Revolut API
            let resp: Response = send(req).await?;

            let body = resp.into_body();
            let string = String::from_utf8(body).expect("Our bytes should be valid utf8");
            // Get the body of the response and parse it using serde_json crate.
            let value: Rate = serde_json::from_str(&string).unwrap();

            println!("{:?}", value);

            payload.values.push(DataFeedResult {
                id: data_feed.id.clone(),
                value: DataFeedResultValue::Numerical(value.rate),
            });
        } else {
            // Report string value, currently only strings with 24 bytes or less are supported
            let value = "Hello awesome Blockchain".to_string();
            if value.len() <= 24 {
                println!("{:?}", value);
                payload.values.push(DataFeedResult {
                    id: data_feed.id.clone(),
                    value: DataFeedResultValue::Text(value),
                });
            } else {
                println!("String value = `{:?}` is too long to be stored in contract. Only 24 chars are supported", value);
            }

        }
    }
    // Return payload to be pushed to sequencer
    Ok(payload)
}
