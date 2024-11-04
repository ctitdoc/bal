import ballerina/http;
import ballerina/io;

public function main() returns error? {

    io:println("srv opportunity API calls tests");

    //conf
    json|io:Error conf = getConf();
    if (conf is error) {
        return conf;
    } else {
        string sellingUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_SELLING_URI");
        io:println(sellingUrl);
        string authUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_AUTH_SERVER_URI");
        io:println(authUrl);
        string gatewayUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_GATEWAY_URI");
        io:println(gatewayUrl);
        io:println();

        //authent providers
        json OFCredentials = check getJsonOFAuthCredentials();

        http:Client OFAuthClient = check new (authUrl);
        string route = "/auth/providers/sign-in";

        json response = check OFPost(OFAuthClient, authUrl, route, OFCredentials, {});

        string token = check response.token;
        map<string> headers = {"Authorization": "Bearer " + token};

        string? email = "";
        if (play("salesPerson")) {
            //get users by point of sale ID
            UserResponse users = check OFAuthClient->get("/users?pointOfSaleIds[]=155&groupTypes[]=3&total=true", headers);
            prGet(sellingUrl + "/users?pointOfSaleIds[]=155&groupTypes[]=3&total=true", users);
            email = users.items[0].email;
        }

        http:Client OFSellingClient = check new (sellingUrl);

        if (play("createOpp")) {
            //get car by chassis and create opportunity
            json jsonOpp = check getJson("Opportunity.json");
            Opportunity opportunity = check jsonOpp.cloneWithType();

            //see https://ballerina.io/learn/by-example/http-client-send-request-receive-response/
            VehResponse vehResp = check OFSellingClient->/vehicles/cars(headers, chassis = <string>opportunity?.chassis, total = true);
            prGet(sellingUrl + "/vehicles/cars?chassis=" + <string>opportunity?.chassis + "&total=true", vehResp);
            int vehId = vehResp.items[0].id;

            route = "/offers";
            opportunity.stockCarId = vehId;
            if (play("salesPerson")) {
                opportunity.attributedUser = {"email": email};
            }
            http:Client OFGatewayClient = check new (gatewayUrl);

            response = check OFPost(OFGatewayClient, gatewayUrl, route, opportunity, headers);

            //adds comment
            OpportunityResponse ofResponse = check response.cloneWithType();

            route = "/opportunities/" + ofResponse.opportunityId + "/comments";
            json body = {
                "comment": "test Franck ajout par API commentaire de l'offre ID " + ofResponse.id
            };

            response = check OFPost(OFSellingClient, sellingUrl, route, body, headers);

            //get opportunit by ID
            json opp = check OFSellingClient->/opportunities/[ofResponse.opportunityId](headers, total = true);
            prGet(sellingUrl + "/opportunities/" + ofResponse.opportunityId + "?total=true", opp);
            OFOffersResponse offers = check OFSellingClient->/opportunities/[ofResponse.opportunityId]/offers(headers);
            prGet(sellingUrl + "/opportunities/" + ofResponse.opportunityId + "/offers?total=true", offers);
            json offer = check OFSellingClient->get(string `/offers?ids[]=${offers.items[0].id}`, headers);
            prGet(string `${sellingUrl}/offers?ids[]=${offers.items[0].id}`, offer);
        }
    }

    if (play("oppStatus")) {
        var db_srv_opportunity = check getDbClient();
        SOOpp[] opps = getOpportunities(db_srv_opportunity);
        io:println(opps);
    }

    if (play("jira")) {
        check jira();
    }

}
