import ballerina/data.jsondata;
import ballerina/http;
import ballerina/io;
import ballerina/os;

public function process(SchemedTalk[] schemedTalks, string countryCode, boolean checkUserAuth = false) returns json|error? {

    //conf
    map<string|map<string>>|error & readonly ofAuths = jsondata:parseString(os:getEnv("OPENFLEX_TEST_AUTH"), {});
    map<string>|error SFCredentials = jsondata:parseString(os:getEnv("SALESFORCE_TEST_AUTH"), {});
    SFCredentials = (SFCredentials is error) ? {} : SFCredentials;

    json conf = {};
    map<string|map<string>> auths = {};
    match ofAuths {
        var e if (e is error) || (e.cloneReadOnly().length() <= 0) => {
            io:println("OPENFLEX_TEST_AUTH env variable is not set or has invalid format or missing values.");
            return;
        }
        _ => {
            auths = check ofAuths;
            conf = check getConf(<string?>auths["env"]);
        }
    }
    json sfConf = check getConf("prod");

    string sellingUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_SELLING_URI");
    io:println(sellingUrl);
    string authUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_AUTH_SERVER_URI");
    io:println(authUrl);
    string gatewayUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_GATEWAY_URI");
    io:println(gatewayUrl);
    string salesforceUrl = check getContainerEnvVar(sfConf, "php-fpm", "SALESFORCE_API_URL");
    //salesforceUrl = "https://login.salesforce.com";
    io:println(salesforceUrl);
    io:println();

    //authent providers

    map<string> OFCredentials = checkUserAuth ? {} : check auths[countryCode].cloneWithType();

    http:Client OFAuthClient = check new (authUrl, {timeout: 180});
    http:Client OFSellingClient = check new (sellingUrl, {timeout: 180});
    http:Client OFGatewayClient = check new (gatewayUrl, {timeout: 180});
    http:Client SFClient = check new (salesforceUrl, {timeout: 180});

    map<map<http:Client|string>> httpClients = {
        "identity": {"client": OFAuthClient, "url": authUrl},
        "selling": {"client": OFSellingClient, "url": sellingUrl},
        "gateway": {"client": OFGatewayClient, "url": gatewayUrl},
        "salesforce": {"client": SFClient, "url": salesforceUrl}
    };

    json response = {};
    json[] responses = [];
    map<string> headers = {};
    map<string> sfHeaders = {};
    string route;
    string? email = "";
    SchemedTalk[] played = [];
    foreach SchemedTalk schemedTalk in schemedTalks {
        if (play(schemedTalk, GET)) {
            GET get = check schemedTalk.cloneWithType();
            schemedTalk.description = get.description;
            io:println("-----");
            io:println(get.description);
            io:println("-----");
            route = check buildRoute(get);
            response = check (<http:Client>httpClients[get.'service]["client"])->get(route, (get.'service != salesforce) ? headers : sfHeaders);
            prGet((<string>httpClients[get.'service]["url"]) + route, response);
        } else if (play(schemedTalk, POST)) {
            POST post = check schemedTalk.cloneWithType();
            schemedTalk.description = post.description;
            io:println("-----");
            io:println(post.description);
            io:println("-----");
            route = check buildRoute(post);
            response = check OFPost(
                    <http:Client>httpClients[post.'service]["client"],
                    <string>httpClients[post.'service]["url"],
                    route, post?.body, headers);
        } else if (play(schemedTalk, SchemedTalkDoc)) {
            SchemedTalkDoc schemedTalkDoc = check schemedTalk.cloneWithType();
            io:println("-----");
            io:println(schemedTalkDoc.description);
            io:println("-----");
            played.push(schemedTalkDoc);
            response = check schemedTalkDoc.cloneWithType();
        } else if (play(schemedTalk, ProvidersEntities)) {
            ProvidersEntities providerEntities = check schemedTalk.cloneWithType();
            schemedTalk.description = providerEntities.description;
            if checkUserAuth {
                OFCredentials = {"id": <string>(providerEntities.id != () ? providerEntities.id : ""), "password": <string>(providerEntities.password != () ? providerEntities.password : "")};
            }
            io:println("-----");
            io:println(providerEntities.description);
            io:println("-----");
            response = check OFPost(OFAuthClient, authUrl, providerEntities.route, OFCredentials, {});
            played.push(providerEntities);
        } else if (play(schemedTalk, AuthProvidersSign_in)) {
            AuthProvidersSign_in authProvidersSign_in = check schemedTalk.cloneWithType();
            schemedTalk.description = authProvidersSign_in.description;
            if checkUserAuth {
                OFCredentials = {"id": <string>(authProvidersSign_in.id != () ? authProvidersSign_in.id : ""), "password": <string>(authProvidersSign_in.password != () ? authProvidersSign_in.password : "")};
            }
            OFCredentials["entityId"] = authProvidersSign_in.entityId;
            io:println("-----");
            io:println(authProvidersSign_in.description);
            io:println("-----");
            response = check OFPost(OFAuthClient, authUrl, authProvidersSign_in.route, OFCredentials, {});
            string token = check response.token;
            headers = {"Authorization": "Bearer " + token};
            played.push(authProvidersSign_in);
        } else if (play(schemedTalk, AuthProvidersPassword)) {
            AuthProvidersPassword authProvidersPassword = check schemedTalk.cloneWithType();
            schemedTalk.description = authProvidersPassword.description;
            io:println("-----");
            io:println(authProvidersPassword.description);
            io:println("-----");
            response = check OFPatch(OFAuthClient, authUrl,
                    string `${authProvidersPassword.route}/${authProvidersPassword.currentPassword}}`,
                    {"password": authProvidersPassword.newPassword}, {});
            played.push(authProvidersPassword);
        } else if (play(schemedTalk, Users)) {
            Users users = check schemedTalk.cloneWithType();
            schemedTalk.description = users.description;
            route = string `${users.route}?`;
            foreach string id in users.pointOfSaleIds {
                route += string `pointOfSaleIds[]=${id}&`;
            }
            foreach string 'type in users.groupTypes {
                route += string `groupTypes[]=${'type}&`;
            }
            route += "total=true";
            io:println("-----");
            io:println(users.description);
            io:println("-----");
            UserResponse userResponse = check OFAuthClient->get(route, headers);
            prGet(authUrl + route, userResponse);
            email = userResponse.items[0].email;
            played.push(users);
            response = check userResponse.cloneWithType();
        } else if (play(schemedTalk, CreateOpportunity)) {
            json[] talkResponses = [];
            CreateOpportunity createOpportunity = check schemedTalk.cloneWithType();
            schemedTalk.description = createOpportunity.description;
            Opportunity opportunity = check createOpportunity.opportunity.cloneWithType();
            io:println("-----");
            io:println(createOpportunity.description);
            io:println("-----");

            //get car by chassis and create opportunity
            //see https://ballerina.io/learn/by-example/http-client-send-request-receive-response/
            VehResponse vehResp = check OFSellingClient->/vehicles/cars(headers, chassis = (opportunity?.chassis != ()) ? <string>opportunity?.chassis : "", total = true);
            talkResponses.push(check vehResp.cloneWithType(json));
            prGet(sellingUrl + "/vehicles/cars?chassis=" + <string>opportunity?.chassis + "&total=true", vehResp);
            int vehId = vehResp.items[0].id;

            route = createOpportunity.route;
            opportunity.stockCarId = vehId;
            if (hasPlayed(played, Users)) {
                opportunity.attributedUser = {"email": email};
            }

            response = check OFPost(OFGatewayClient, gatewayUrl, route, opportunity, headers);
            talkResponses.push(response);

            //adds comment
            OpportunityResponse ofResponse = check response.cloneWithType();

            route = "/opportunities/" + ofResponse.opportunityId + "/comments";
            json body = {
                "comment": "test Franck ajout par API commentaire de l'offre ID " + ofResponse.id
            };

            talkResponses.push(check OFPost(OFSellingClient, sellingUrl, route, body, headers));

            //get opportunit by ID
            json opp = check OFSellingClient->/opportunities/[ofResponse.opportunityId](headers, total = true);
            prGet(sellingUrl + "/opportunities/" + ofResponse.opportunityId + "?total=true", opp);
            OFOffersResponse offers = check OFSellingClient->/opportunities/[ofResponse.opportunityId]/offers(headers);
            talkResponses.push(check offers.cloneWithType(json));
            prGet(sellingUrl + "/opportunities/" + ofResponse.opportunityId + "/offers?total=true", offers);
            json offer = check OFSellingClient->get(string `/offers?ids[]=${offers.items[0].id}`, headers);
            talkResponses.push(check offer.cloneWithType(json));
            prGet(string `${sellingUrl}/offers?ids[]=${offers.items[0].id}`, offer);
            response = check talkResponses.cloneWithType();
        } else if (play(schemedTalk, SFAuthToken)) {
            SFAuthToken sfAuthToken = check schemedTalk.cloneWithType();
            schemedTalk.description = sfAuthToken.description;
            io:println("-----");
            io:println(sfAuthToken.description);
            io:println("-----");
            if checkUserAuth {
                SFCredentials = {
                    "username": <string>(sfAuthToken.username != () ? sfAuthToken.username : ""),
                    "password": <string>(sfAuthToken.password != () ? sfAuthToken.password : ""),
                    "client_id": <string>(sfAuthToken.client_id != () ? sfAuthToken.client_id : ""),
                    "client_secret": <string>(sfAuthToken.client_secret != () ? sfAuthToken.client_secret : ""),
                    "grant_type": "password"
                };
            }
            response = check OFPost(SFClient, salesforceUrl, sfAuthToken.route, check SFCredentials, {"Content-Type": "application/x-www-form-urlencoded"}, true);
            string token = check response.access_token;
            sfHeaders = {"Authorization": "Bearer " + token};
            played.push(sfAuthToken);
        }
        if (!play(schemedTalk, SchemedTalkDoc)) {
            responses.push((schemedTalk.description != ()) ? {"description": schemedTalk.description} : {"description": ""});
        }
        responses.push(response);
    }

    return responses;
}
