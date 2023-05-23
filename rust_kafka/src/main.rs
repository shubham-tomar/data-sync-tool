use rdkafka::consumer::{BaseConsumer, Consumer};
use rdkafka::producer::{BaseProducer, BaseRecord};
use rdkafka::config::{ClientConfig, RDKafkaLogLevel};
use rdkafka::message::{Message};
use serde_json::Value;

fn main() {
    let consumer: BaseConsumer = ClientConfig::new()
        .set("group.id", "my-group")
        .set("bootstrap.servers", "host.docker.internal:9092")
        .set("enable.partition.eof", "false")
        .set("session.timeout.ms", "6000")
        .set("enable.auto.commit", "true")
        .set("auto.commit.interval.ms", "1000")
        .set("auto.offset.reset", "earliest")
        .create()
        .expect("Consumer creation failed");

    let producer: BaseProducer = ClientConfig::new()
        .set("bootstrap.servers", "host.docker.internal:9092")
        .set("message.timeout.ms", "5000")
        .set("message.send.max.retries", "3")
        .set_log_level(RDKafkaLogLevel::Debug)
        .create()
        .expect("Producer creation failed");

    // Subscribe to kafka topic from which your application will consume
    consumer
        .subscribe(&["dbserver1.inventory.orders"])
        .expect("Can't subscribe to specified topic");

    loop {
        match consumer.poll(std::time::Duration::from_millis(100)) {
            Some(Ok(msg)) => {
                println!(
                    "Received message: topic='{}', partition={}, offset={}, payload='{}'",
                    msg.topic(),
                    msg.partition(),
                    msg.offset(),
                    match msg.payload_view::<str>() {
                        None => "",
                        Some(Ok(s)) => s,
                        Some(Err(e)) => {
                            println!("Error while deserializing message payload: {:?}", e);
                            ""
                        }
                    }
                );
                let payload_str = msg.payload_view::<str>().unwrap().unwrap();
                let payload_json: Value = serde_json::from_str(payload_str).unwrap();
                let log = payload_json["payload"].to_string();
                println!("Formated payload: {}", log);

                let delivery_status = producer.send(
                    BaseRecord::to("test-topic1") // topic which clickhouse will consume from
                        .payload(&log)
                        .key("some-key"),
                );
                match delivery_status {
                    Ok(_) => println!("Message delivered to Kafka"),
                    Err(e) => println!("Error delivering message to Kafka: {:?}", e),
                }

            }
            Some(Err(e)) => println!("Error while receiving message: {:?}", e),
            None => (),
        }
    }}
