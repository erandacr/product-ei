package samples.router;

import ballerina.net.http;
import ballerina.log;

@http:configuration {basePath:"/ecom"}
service<http> GatewayService {

    endpoint<http:HttpClient> browseServiceEP {
        create http:HttpClient("http://localhost:9090/browse", {});
    }

    endpoint<http:HttpClient> orderServiceEP {
        create http:HttpClient("http://localhost:9090/order", {});
    }

    endpoint<http:HttpClient> shipmentServiceEP {
        create http:HttpClient("http://localhost:9090/shipment", {});
    }

    endpoint<http:HttpClient> paymentServiceEP {
        create http:HttpClient("http://localhost:9090/payment", {});
    }

    @http:resourceConfig {
        methods:["GET","POST"],
        path:"/{serviceType}/*"
    }
    resource route (http:Request req, http:Response resp, string serviceType) {
        println("Message received to Router");

        var requestURL = req.getProperty("REQUEST_URL");
        string postfix = requestURL.replaceFirst("/ecom/" + serviceType, "");

        setXFwdForHeader(req);

        http:Response responseMessage = {};

        if (serviceType.hasPrefix("browse")) {
            responseMessage, _ = browseServiceEP.get(postfix, req);
        } else if (serviceType.hasPrefix("order")) {
            responseMessage, _ = orderServiceEP.post("/placeOrder", req);
        } else if (serviceType.hasPrefix("payment")) {
            json payload = req.getJsonPayload();
            var cardType,_ = (string) payload.creditCardType;
            if (cardType.equalsIgnoreCase("VISA")) {
                responseMessage, _ = paymentServiceEP.post("/visa/"  + postfix, req);
            } else if (cardType.equalsIgnoreCase("Master")) {
                responseMessage, _ = paymentServiceEP.post("/master/"  + postfix, req);
            } else {
                payload = {"Error":"Invalid Payment Type"};
                responseMessage.setJsonPayload(payload);
            }
        } else if (serviceType.hasPrefix("shipment")) {
            if (req.userAgent == "Ecom-Agent") {
                responseMessage, _ = shipmentServiceEP.post("/internal/" + postfix, req);
            } else {
                responseMessage, _ = shipmentServiceEP.post("/submit/" + postfix, req);
            }
        } else {
            json payload = {"Error":"No service found"};
            responseMessage.setJsonPayload(payload);
        }

        http:HttpConnectorError respondError = resp.forward(responseMessage);

        if(respondError != null) {
            log:printError("Error occured at GatewayService when forwarding");
        }
    }
}

function setXFwdForHeader(http:Request req) {
    http:HeaderValue headerValue = req.getHeader("X-Forwarded-For");

    string xFwdHeader;

    if (headerValue != null) {
        xFwdHeader = headerValue.value + ", 10.100.1.127";
    } else {
        xFwdHeader = "10.100.1.127";
    }
    println("Setting X-Forwarded-For to : " + xFwdHeader);

    req.addHeader("X-Forwarded-For", xFwdHeader);
}