# data-sync-tool
syncing tool for different data sources, unified application for ETLs and streams

# rust-kafka Application
- This application will capture INSERT/UPDATE operation on MySQL and push data to Clickhouse in realtime
- Tools used (MySQL, Kafka, Debezium, Clickhouse, Docker, zookepper) and Language: Rust, Detailed steps on
  how to run this app can be found in: https://github.com/shubham-tomar/data-sync-tool/blob/main/rust_kafka/helper_docs.txt
- This application is build for Change Data Capture (CDC) use case.
- Once this application is running, any insert/update/delete made in MYSQL will go to kafka topic t1 (via debezium) 
- There is a rust application running which will read from this topic do required transformations and push to separate kafka topic t2
- We are using clickhouse as Analytics DB, where we will be running queue which will read data from this topic t2
- Once data is there in clickhouse queue table, our materialized view will be triggerd, where we can perform any aggregations if required 
- Once MV is triggered it will push data to main table which can be used for analytical queries

# json-to-ndjson
- While using bqcli i faced an issue where all the data is returned as array of json
- This application parse this array of json to json Each Row (with transformations if required)
- further i needed to do this for mulitple files so wrote a small bash script to perform this parallely in 10 files batch
- eg: Input: [{"col1": "False", "amount": "123.50", "tax_amount": "12"}, {"col1": "1", "amount": "113.50", "tax_amount": "12.5"}]
- output:{"col1": false, "amount": 123.5, "tax_amount": 12}\n
{"col1": true, "amount": 113.5, "tax_amount": 12.5}
