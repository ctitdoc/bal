import ballerina/http;
import ballerina/io;

// A `ResponseErrorInterceptor` service class implementation.
service class ResponseErrorInterceptor {
    *http:ResponseErrorInterceptor;

    // The error occurred in the request-response path can be accessed by the 
    // mandatory argument: `error`. The remote function can return a response,
    // which will overwrite the existing error response.
    remote function interceptResponseError(error err) returns http:BadRequest {
        // In this case, all the errors are sent as `400 BadRequest` responses with a customized
        // media type and body. Moreover, you can send different status code responses according to
        // the error type.        
        return {
            mediaType: "application/org+json",
            body: {message: err.message()}
        };
    }
}

configurable int port = 9090;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}

service http:Service / on new http:Listener(port) {

    // Service-level error interceptors can handle errors occurred during the service execution.
    public function createInterceptors() returns ResponseErrorInterceptor {
        // To handle all of the errors, the `ResponseErrorInterceptor` is added as a first
        // interceptor as it has to be executed last.
        return new ResponseErrorInterceptor();
    }

    function init() {
        io:println(string `listening for schemed talk on port ${port}...`);
        io:println();
    }

    resource function post schemed_talks(http:Request request, SchemedTalk[] schemedTalks) returns json|http:BadRequest {
        json|error response = process(schemedTalks, "IT", true);

        string requestEmitterIP = getRequestEmitterIP(request);

        match response {
            var e if e is error => {
                error|() e1 = io:fileWriteJson(string `./responses/${requestEmitterIP}.json`, [e.message()]);
                return http:BAD_REQUEST;
            }
            var foo if foo is json => {
                error|() e = io:fileWriteJson(string `./responses/${requestEmitterIP}.json`, foo);
                return response;
            }
        }
    }

    resource function post schemed_talks_responses(http:Request request) returns json {
        string requestEmitterIP = getRequestEmitterIP(request);
        json|error content = io:fileReadJson(string `./responses/${requestEmitterIP}.json`);
        match content {
            var e if e is error => {
                return "No response found.";
            }
            var foo if foo is json => {
                return content;
            }
            _ => {
                return "Error while retrieving responses";
            }
        }
    }
    resource function get openapi() returns string|error {
        io:println(string `return openapi contract...`);
        return check io:fileReadString("./schemed_talk_service_openapi.yaml");
    }

    resource function get openapi_dev() returns string|error {
        io:println(string `return openapi dev contract...`);
        return check io:fileReadString("./schemed_talk_service_openapi_dev.yaml");
    }

}
