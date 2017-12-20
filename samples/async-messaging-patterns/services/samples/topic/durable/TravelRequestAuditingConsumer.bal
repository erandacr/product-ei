package samples.topic.durable;

import ballerina.net.jms;
import ballerina.net.http;
import ballerina.runtime;

@Description {value:"Retreive the order message from the queue and reliably send it to downstream service"}
@jms:configuration {
    initialContextFactory:"wso2mbInitialContextFactory",
    providerUrl:"amqp://admin:admin@carbon/carbon?brokerlist='tcp://localhost:5672'",
    connectionFactoryName:"TopicConnectionFactory",
    destination:"TravelRequestTopic",
    subscriptionId:"auditSub",
    connectionFactoryType:jms:TYPE_TOPIC
}
service<jms> travelRequestAuditingConsumer {

    endpoint<http:HttpClient> orderDispatchEp {
        create http:HttpClient("http://localhost:9092/dispatch", {});
    }

    resource onMessage (jms:JMSMessage m) {
        // Retrieve the order message obtained from the queue
        string travelRequestTextMessage = m.getTextMessageContent();
        // convert the message to json
        var travelRequestMessage,_ = <json> travelRequestTextMessage;
        http:HttpConnectorError travelOrderDispatchError;
        //Create a http message based on the content specified in JMS message
        http:Request travelOrderRequest = {};
        travelOrderRequest.setJsonPayload(travelRequestMessage);
        //Create a place holder to retrieve the response obtained from travel order service
        http:Response travelOrderResponse = {};
        //Dispatch the order message to the respective endpoint.
        travelOrderResponse, travelOrderDispatchError = orderDispatchEp.post("/travelAudit", travelOrderRequest);
        //Check if there's an error, if there's no error the message will be polled from the queue upon completion of
        //this operation
        if (travelOrderDispatchError != null) {
            println("Error occurred while dispatching the message, hence message will be retried");
            //We specify an interval to control the retry frequency, as we do not intend to retry sending the message
            //immediately. In this case we wait for 6 seconds if an error occurs
            runtime:sleepCurrentThread(6000);
            //Acknowledge with an error so that the broker would not poll the message from the queue, rather the
            //broker would initiate re-send.
            m.acknowledge(jms:DELIVERY_ERROR);
        }
    }
}
