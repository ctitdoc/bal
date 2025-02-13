import ballerina/http;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/sql;
import ballerina/url;
import ballerinax/mysql;

//see https://ballerina.io/learn/by-example/http-client-send-request-receive-response/

// public function OFPost(http:Client apiClient, string apiUrl, string route, anydata body, map<string>? headers) returns json|error {
//     io:println("call POST " + apiUrl + route);
//     io:println("with body:");
//     io:println(body);
//     json response = ();
//     if (headers != ()) {
//     response = check apiClient->post(route, body, headers);
//     } else {
//         response = check apiClient->post(route, body, headers);
//     }
//     io:println("receive response:");
//     io:println(response);
//     io:println();
//     return response;
// }

public function OFUpdate(string updateMethod, http:Client apiClient, string apiUrl, string route, anydata body, map<string>? headers, boolean urlEncodeBody = false) returns json|error {
    io:println("call " + updateMethod + " " + apiUrl + route);
    io:println("with body:");
    io:println(body);
    string urlEncodedBody = "";
    if (urlEncodeBody) {
        urlEncodedBody = encodeParams(<map<string>>body);
        io:println("body urlencoded version:");
        io:println(urlEncodedBody);
    }
    anydata processedBody = urlEncodeBody ? urlEncodedBody : body;
    json response = ();
    if (headers != ()) {
        if (updateMethod == "POST") {
            response = check apiClient->post(route, processedBody, headers);
        } else if (updateMethod == "PATCH") {
            response = check apiClient->patch(route, processedBody, headers);
        }
    } else {
        if (updateMethod == "PATCH") {
            response = check apiClient->post(route, processedBody);
        } else if (updateMethod == "PATCH") {
            response = check apiClient->patch(route, processedBody);
        }
    }
    io:println("receive response:");
    io:println(response);
    io:println();
    return response;
}

function resolveExpressions(string jsonString, json response, map<json> memory = {}) returns SchemedTalk|error {

    string:RegExp regex = re `<\?([:\w]+)\?>`;
    if !(response is map<json>) {
        SchemedTalk resolvedSchemedTalk = check (<anydata>(check jsonString.fromJsonString())).cloneWithType();
        return resolvedSchemedTalk;
    }
    //see https://github.com/ballerina-platform/ballerina-lang/issues/42331
    // about isolation, readonlyness and finalness...
    final map<json> & readonly work = response.cloneReadOnly();
    final map<json> & readonly mem = memory.cloneReadOnly();

    regexp:Replacement replaceFunction = isolated function(regexp:Groups groups) returns string {
        regexp:Span? span = groups[1];
        if (span == ()) {
            return "";
        }
        string key = span.substring();
        string:RegExp memoryPattern = re `memory:(\w+)`;
        json? value = ();
        if memoryPattern.matchAt(key, 0) is regexp:Span {
            regexp:Groups? memoryGroup = memoryPattern.findGroups(key);
            if memoryGroup is () {return "<?" + key + "?>";}
            regexp:Span? memorySpan = memoryGroup[1];
            if memorySpan is () {return "<?" + key + "?>";}
            key = memorySpan.substring();
            value = mem[key];
            if value is string {
                return value;
            } else {
                return "<?" + key + "?>";
            }
        } else {
            value = work[key];
            if value is string {
                return value;
            } else {
                return "<?" + key + "?>";
            }
        }
    };

    string result = regex.replace(jsonString, replaceFunction);
    SchemedTalk resolvedSchemedTalk = check (<anydata>(check result.fromJsonString())).cloneWithType();
    return resolvedSchemedTalk;
}

function encodeParams(map<string> params) returns string {
    string encodedParams = "";
    foreach var [key, value] in params.entries() {
        string encodedKey = checkpanic url:encode(key, "UTF-8");
        string encodedValue = checkpanic url:encode(value, "UTF-8");
        encodedParams += encodedKey + "=" + encodedValue + "&";
    }
    return encodedParams;
}

public function OFPatch(http:Client apiClient, string apiUrl, string route, anydata body, map<string>? headers, boolean urlEncodeBody = false) returns json|error {
    return OFUpdate("PATCH", apiClient, apiUrl, route, body, headers, urlEncodeBody);
}

public function OFPost(http:Client apiClient, string apiUrl, string route, anydata body, map<string>? headers, boolean urlEncodeBody = false) returns json|error {
    return OFUpdate("POST", apiClient, apiUrl, route, body, headers, urlEncodeBody);
}

public function prGet(string url, anydata response) {
    io:println("call GET " + url);
    io:println("receive response:");
    io:println(response);
    io:println();
}

public function getDbClient() returns mysql:Client|sql:Error {
    final mysql:Client|sql:Error dbClient = new ("localhost", "root", "root", "srv_opportunity", 3310);
    return dbClient;
}

isolated function getOpportunities(mysql:Client dbClient) returns SOOpp[] {
    SOOpp[] opportunities = [];
    stream<SOOpp, error?> resultStream = dbClient->query(
        `SELECT openflex_opportunity_id, status FROM opportunity`
    );
    error? status = from SOOpp opportunity in resultStream
        do {
            opportunities.push(opportunity);
        };
    status = resultStream.close();
    return opportunities;
}

public function play(string|SchemedTalk scenarioId, typedesc<anydata> typeDesc = never) returns boolean {
    if (scenarioId is string) {
        return scenarios.indexOf(<string>scenarioId) != () || scenarios.indexOf("all") != ();
    }
    var value = scenarioId.cloneWithType(typeDesc);
    match (value) {
        var x if x is error => {
            return false;
        }
        _ => {
            return true;
        }
    }
    return false;
}

public function hasPlayed((SchemedTalk|map<json>)[] schemedTalks, typedesc<anydata> typeDesc = never) returns boolean {
    (SchemedTalk|map<json>)[] result = from (SchemedTalk|map<json>) schemedTalk in schemedTalks
        where typeof schemedTalk === typeDesc
        select schemedTalk;
    return (result.length() > 0);
}

public function buildRoute(GET|POST|PATCH request) returns string|error {
    string route = <string>request.route;
    if (request?.parameters != ()) {
        route += "?";
        map<string|int|float|boolean|(string|int|float|boolean)[]> params = check request?.parameters.cloneWithType();
        foreach string key in params.keys() {
            if (params[key] is (string|int|float|boolean)[]) {
                (string|int|float)[] values = check params[key].cloneWithType();
                foreach var value in values {
                    route += string `${key}[]=${value}&`;
                }
            } else {
                (string|int|float|boolean) value = <(string|int|float|boolean)>params[key];
                route += string `${key}=${value}&`;
            }
        }
    }
    return route;
}

function extractIP(string headerValue, string fallbackValue) returns string {
    regexp:RegExp ipPattern = re `\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b`;
    regexp:Span? span = ipPattern.find(headerValue);
    return span is () ? fallbackValue : span.substring();
}

function getRequestEmitterIP(http:Request request) returns string {
    string requestEmitterIP = "localhost";
    string|error headerValue = "";
    if (request.hasHeader("Forwarded")) {
        headerValue = request.getHeader("X-Forwarded");
    } else if (request.hasHeader("X-Forwarded-For")) {
        headerValue = request.getHeader("X-Forwarded-For");
    } else if (request.hasHeader("X-Real-IP")) {
        headerValue = request.getHeader("X-Real-IP");
    }
    match headerValue {
        var e if e is error => {
        }
        _ => {
            requestEmitterIP = extractIP(<string>headerValue, "localhost");
        }
    }
    return requestEmitterIP;
}
