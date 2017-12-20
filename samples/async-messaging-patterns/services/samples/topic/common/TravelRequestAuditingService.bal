package samples.topic.common;

import ballerina.net.http;
import ballerina.log;

@Description {value:"Mimics order auditing service"}
@http:configuration {basePath:"/dispatch",
                     port:9092}
service<http> travelRequestAuditingService {
    @http:resourceConfig {
        methods:["POST"],
        path:"/travelAudit"
    }
    resource dispatchResource (http:Request req, http:Response res) {
        //Retrieve incoming json payload
        json orderPayload = req.getJsonPayload();
        // Print the retrieved payload.
        println("Tavel order will be audited : " + orderPayload.toString());
        //Send a successful response back to the caller
        json responsePayload = {"Status":"Success"};
        http:HttpConnectorError respondError = null;
        res.setJsonPayload(responsePayload);
        respondError= res.send();

        if(respondError != null) {
            log:printError("Error while responding back from the travelRequestAuditingService backend");
        }
    }
}
