import ballerina/data.jsondata;
import ballerina/http;
import ballerina/io;
import ballerina/os;

public function process(SchemedTalk[] schemedTalks, string countryCode, boolean checkUserAuth = false) returns json|error? {

    //conf
    map<string|map<string>>|error & readonly ofAuths = jsondata:parseString(os:getEnv("OPENFLEX_TEST_AUTH"), {});
    map<string>|error & readonly OFUserCredentials = jsondata:parseString(os:getEnv("OPENFLEX_TEST_USER_AUTH"), {});
    map<string>|error SFCredentials = jsondata:parseString(os:getEnv("SALESFORCE_TEST_AUTH"), {});
    SFCredentials = (SFCredentials is error) ? {} : SFCredentials;
    map<string>|error SOCredentials = jsondata:parseString(os:getEnv("SRV_OPPORTUNITY_TEST_AUTH"), {});
    SOCredentials = (SOCredentials is error) ? {} : SOCredentials;

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

    json sfConf = check getConf(<string?>auths["env"]);

    string sellingUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_SELLING_URI");
    io:println(sellingUrl);
    string authUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_AUTH_SERVER_URI");
    io:println(authUrl);
    string gatewayUrl = check getContainerEnvVar(conf, "php-fpm", "OPENFLEX_GATEWAY_URI");
    io:println(gatewayUrl);
    string salesforceUrl = check getContainerEnvVar(sfConf, "php-fpm", "SALESFORCE_API_URL");
    io:println(salesforceUrl);
    string soUrl = <string>(check SOCredentials)["url"];
    io:println(soUrl);
    io:println();

    //authent providers

    map<string> OFCredentials = checkUserAuth ? {} : check auths[countryCode].cloneWithType();

    http:Client OFAuthClient = check new (authUrl, {timeout: 180});
    http:Client OFSellingClient = check new (sellingUrl, {timeout: 180});
    http:Client OFGatewayClient = check new (gatewayUrl, {timeout: 180});
    http:Client SFClient = check new (salesforceUrl, {timeout: 180});
    http:Client SOClient = check new (soUrl, {timeout: 180});

    map<string> headers = {};
    map<string> userHeaders = {};
    map<string> sfHeaders = {};
    map<string> soHeaders = {};

    map<map<http:Client|string|map<string>>> httpClients = {
        identity: {"client": OFAuthClient, "url": authUrl, "headers": headers, "userHeaders": userHeaders},
        selling: {"client": OFSellingClient, "url": sellingUrl, "headers": headers, "userHeaders": userHeaders},
        gateway: {"client": OFGatewayClient, "url": gatewayUrl, "headers": headers},
        salesforce: {"client": SFClient, "url": salesforceUrl, "headers": sfHeaders},
        srv_opportunity: {"client": SOClient, "url": soUrl, "headers": soHeaders}
    };

    json response = {};
    json[] responses = [];
    string route;
    string? email = "";
    (SchemedTalk|map<json>)[] played = [];
    map<json> memory = {};
    foreach SchemedTalk schemedTalk in schemedTalks {
        SchemedTalk resolvedSchemedTalk = check resolveExpressions(schemedTalk.toJsonString(), response, memory);
        if (play(resolvedSchemedTalk, GET)) {
            GET get = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = get.description;
            printTitle(get.description);
            route = check buildRoute(get);
            response = check (<http:Client>httpClients[get.'service]["client"])->get(route, <map<string>>httpClients[get.'service][get.headers]);
            prGet((<string>httpClients[get.'service]["url"]) + route, response);
        } else if (play(resolvedSchemedTalk, POST)) {
            POST post = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = post.description;
            printTitle(post.description);
            route = check buildRoute(post);
            response = check OFPost(
                    <http:Client>httpClients[post.'service]["client"],
                    <string>httpClients[post.'service]["url"],
                    route, post?.body, <map<string>>httpClients[post.'service][post.headers]);
        } else if (play(resolvedSchemedTalk, PUT)) {
            PUT put = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = put.description;
            printTitle(put.description);
            route = check buildRoute(put);
            response = check OFPost(
                    <http:Client>httpClients[put.'service]["client"],
                    <string>httpClients[put.'service]["url"],
                    route, put?.body, <map<string>>httpClients[put.'service][put.headers]);
        } else if (play(resolvedSchemedTalk, PATCH)) {
            PATCH patch = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = patch.description;
            printTitle(patch.description);
            route = check buildRoute(patch);
            response = check OFPatch(
                    <http:Client>httpClients[patch.'service]["client"],
                    <string>httpClients[patch.'service]["url"],
                    route, patch?.body, <map<string>>httpClients[patch.'service][patch.headers]);
        } else if (play(resolvedSchemedTalk, SchemedTalkDoc)) {
            SchemedTalkDoc schemedTalkDoc = check resolvedSchemedTalk.cloneWithType();
            printTitle(schemedTalkDoc.description);
            played.push(schemedTalkDoc);
            response = check schemedTalkDoc.cloneWithType();
        } else if (play(resolvedSchemedTalk, ProvidersEntities)) {
            ProvidersEntities providerEntities = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = providerEntities.description;
            if checkUserAuth {
                OFCredentials = {"id": <string>(providerEntities.id != () ? providerEntities.id : ""), "password": <string>(providerEntities.password != () ? providerEntities.password : "")};
            }
            printTitle(providerEntities.description);
            response = check OFPost(OFAuthClient, authUrl, providerEntities.route, OFCredentials, {});
            played.push(providerEntities);
        } else if (play(resolvedSchemedTalk, AuthProvidersSign_in)) {
            AuthProvidersSign_in authProvidersSign_in = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = authProvidersSign_in.description;
            if checkUserAuth {
                OFCredentials = {"id": <string>(authProvidersSign_in.id != () ? authProvidersSign_in.id : ""), "password": <string>(authProvidersSign_in.password != () ? authProvidersSign_in.password : "")};
            }
            OFCredentials["entityId"] = authProvidersSign_in.entityId;
            printTitle(authProvidersSign_in.description);
            response = check OFPost(OFAuthClient, authUrl, authProvidersSign_in.route, OFCredentials, {});
            string token = check response.token;
            headers = {"Authorization": "Bearer " + token};
            httpClients[authProvidersSign_in.'service]["headers"] = headers;
            httpClients[selling]["headers"] = headers;
            httpClients[gateway]["headers"] = headers;
            played.push(authProvidersSign_in);
        } else if (play(resolvedSchemedTalk, AuthUsersSign_in)) {
            AuthUsersSign_in authUsersSign_in = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = authUsersSign_in.description;
            if checkUserAuth {
                OFUserCredentials = {
                                        "id": <string>(authUsersSign_in.id != () ? authUsersSign_in.id : ""), 
                                        "password": <string>(authUsersSign_in.password != () ? authUsersSign_in.password : ""),
                                        "mfaToken": <string>(authUsersSign_in.mfaToken != () ? authUsersSign_in.mfaToken : "")
                                    };
            }
            printTitle(authUsersSign_in.description);
            response = check OFPost(OFAuthClient, authUrl, authUsersSign_in.route, check OFUserCredentials, {});
            string token = check response.token;
            userHeaders = {"Authorization": "Bearer " + token};
            httpClients[authUsersSign_in.'service]["userHeaders"] = userHeaders;
            httpClients[selling]["userHeaders"] = userHeaders;
            played.push(authUsersSign_in);
        } else if (play(resolvedSchemedTalk, AuthProvidersPassword)) {
            AuthProvidersPassword authProvidersPassword = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = authProvidersPassword.description;
            printTitle(authProvidersPassword.description);
            response = check OFPatch(OFAuthClient, authUrl,
                    string `${authProvidersPassword.route}/${authProvidersPassword.currentPassword}}`,
                    {"password": authProvidersPassword.newPassword}, {});
            played.push(authProvidersPassword);
        } else if (play(resolvedSchemedTalk, Users)) {
            Users users = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = users.description;
            route = string `${users.route}?`;
            foreach string id in users.pointOfSaleIds {
                route += string `pointOfSaleIds[]=${id}&`;
            }
            foreach string 'type in users.groupTypes {
                route += string `groupTypes[]=${'type}&`;
            }
            route += "total=true";
            printTitle(users.description);
            UserResponse userResponse = check OFAuthClient->get(route, headers);
            prGet(authUrl + route, userResponse);
            email = userResponse.items[0].email;
            played.push(users);
            response = check userResponse.cloneWithType();
        } else if (play(resolvedSchemedTalk, CreateOpportunity)) {
            json[] talkResponses = [];
            CreateOpportunity createOpportunity = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = createOpportunity.description;
            Opportunity opportunity = check createOpportunity.opportunity.cloneWithType();
            printTitle(createOpportunity.description);

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
        } else if (play(resolvedSchemedTalk, SFAuth2Token)) {
            SFAuth2Token sfAuthToken = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = sfAuthToken.description;
            printTitle(sfAuthToken.description);
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
            httpClients[sfAuthToken.'service]["headers"] = sfHeaders;
            played.push(sfAuthToken);
        } else if (play(resolvedSchemedTalk, SOApiLoginCheck)) {
            SOApiLoginCheck soApiLoginCheck = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = soApiLoginCheck.description;
            printTitle(soApiLoginCheck.description);
            if checkUserAuth {
                SOCredentials = {
                    "username": <string>(soApiLoginCheck.username != () ? soApiLoginCheck.username : ""),
                    "password": <string>(soApiLoginCheck.password != () ? soApiLoginCheck.password : ""),
                    "url": soUrl
                };
            }
            map<string> credentials = (check SOCredentials);
            string url = credentials.remove("url");
            response = check OFPost(SOClient, soUrl, soApiLoginCheck.route, credentials, {});
            string token = check response.token;
            soHeaders = {"Authorization": "Bearer " + token};
            httpClients[soApiLoginCheck.'service]["headers"] = soHeaders;
            played.push(soApiLoginCheck);
        } else if (play(resolvedSchemedTalk, SOApiOpportunities)) {
            SOApiOpportunities soApiOpportunities = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = soApiOpportunities.description;
            printTitle(soApiOpportunities.description);
            response = check OFPost(SOClient, soUrl, soApiOpportunities.route, soApiOpportunities.body, <map<string>>httpClients[soApiOpportunities.'service]["headers"]);
            played.push(soApiOpportunities);
        } else if (play(resolvedSchemedTalk, Memorize)) {
            Memorize memorize = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = memorize.description;
            printTitle(memorize.description);
            foreach [string, string|int] [key, value] in memorize.asWhat.entries() {
                if response is map<json> && value is string && response[value] is json {
                    memory[key] = response[value];
                }
                if response is json[] && value is int && response[value] is json {
                    memory[key] = response[value];
                }
            }
            response = memory;
            io:println("response of Memorize request is current memory state:");
            io:println(response);
            io:println();
            played.push(memorize);
        } else if (play(resolvedSchemedTalk, IsSubset)) {
            IsSubset issubset = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = issubset.description;
            printTitle(issubset.description);
            if (issubset.values.length() == 0) {
                response = "No values to compare";
            }
            if (issubset.values.length() == 1) {
                response = isSubset(response, issubset.values[0]);
            } else {
                response = isSubset(issubset.values[0], issubset.values[1]);
            }
            io:println("response of IsSubset is:");
            io:println(response);
            io:println();
            played.push(issubset);
        } else if (play(resolvedSchemedTalk, Equal)) {
            Equal equal = check resolvedSchemedTalk.cloneWithType();
            resolvedSchemedTalk.description = equal.description;
            printTitle(equal.description);
            if (equal.values.length() == 0) {
                response = "No values to compare";
            }
            if (equal.values.length() == 1) {
                response = (response == equal.values[0]);
            } else {
                response = equal.values[0] == equal.values[1];
            }
            io:println("response of Equal is:");
            io:println(response);
            io:println();
            played.push(equal);
        }

        if (!play(resolvedSchemedTalk, SchemedTalkDoc)) {
            responses.push((resolvedSchemedTalk.description != ()) ? {"description": resolvedSchemedTalk.description} : {"description": ""});
        }
        responses.push(response);
    }

    return responses;
}

function printTitle(string text) {
            io:println("-----");
            io:println(text);
            io:println("-----");
}