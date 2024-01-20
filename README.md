# data-sync-tool
syncing tool for different data sources, unified application for ETLs and streams

# rust-kafka Application
- This application will capture INSERT/UPDATE operation on MySQL and push data to Clickhouse in realtime
- Tools used (MySQL, Kafka, Debezium, Clickhouse, Docker) and Language: Rust, Detailed steps on
  how to run this app can be found in: /data-sync-tool/rust_kafka/helper_docs.txt
- This application is build for Change Data Capture (CDC) use case.
- Once this application is running, any insert/update/delete made in MYSQL will go to kafka topic t1 (via debezium) 
- There is a rust application running which will read from this topic do required transformations and push to separate kafka topic t2
- We are using clickhouse as Analytics DB, where we will be running queue which will read data from this topic t2
- Once data is there in clickhouse queue table, our materialized view will be triggerd, where we can perform any aggregations if required 
- Once MV is triggered it will push data to main table which can be used for analytical queries
