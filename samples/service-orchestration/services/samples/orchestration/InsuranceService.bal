package samples.orchestration;

import ballerina.net.http;
import ballerina.log;

@http:configuration {basePath:"/insurance"}
service<http> InsuranceService {
    @http:resourceConfig {
        methods:["GET"],
        path:"/validate/{vehicleId}"
    }
    resource validatePolicy (http:Request req, http:Response resp, string vehicleId) {
        println("Validating insurance policy");

        json payload;
        if (vehicleId == "11111") { 
            // This is just a dummy validation
            payload = {"Status":"Valid"};
        } else {
            payload = {"Status":"Invalid"};
        }

        resp.setJsonPayload(payload);

        http:HttpConnectorError respondError = null;
        respondError = resp.send();

        if(respondError != null) {
            log:printError("Error occured at InsuranceService while responding back");
        }
    }
}