
public type SchemedTalk record {
    string 'type?;
    string description?;
    SchemedTalk[] talkScheme?;
};

public type SchemedTalkDoc record {
    *SchemedTalk;
    "SchemedTalkDoc" 'type = "SchemedTalkDoc";
    string description;
};

public enum ManagedService {
    identity, selling, gateway, salesforce, srv_opportunity
};

type RequestType record {
    *SchemedTalk;
    ManagedService 'service;
    string 'type = "Request";
    string route?;
    string headers = "headers";
};

type GETRequestType record {
    *RequestType;
    string 'type = "GET";
    map<string|int|float|boolean|(string|int|float|boolean)[]>? parameters?;
};

type GET record {
    *GETRequestType;
    "GET" 'type = "GET";
    string description = "Request type GET executes an openflex or salesforce HTTP GET request: property service identifies one of the following OF/SF/SO services: identity, selling, gateway, salesforce, srv_opportunity; route is the URI of the http request, parameters property are the http parameters and body of the request";
};

type POSTRequestType record {
    *GETRequestType;
    string 'type = "POST";
    json body?;
};

type POST record {
    *POSTRequestType;
    "POST" 'type = "POST";
    string description = "Request type POST executes an openflex or salesforce HTTP POST request: property service identifies one of the following OF/SF/SO services: identity, selling, gateway, salesforce, srv_opportunity; route is the URI of the http request, parameters and body properties are the http parameters and body of the request";
};

type PUT record {
    *POSTRequestType;
    "PUT" 'type = "PUT";
    string description = "Request type PUT executes an openflex or salesforce HTTP PUT request: property service identifies one of the following OF/SF/SO services: identity, selling, gateway, salesforce, srv_opportunity; route is the URI of the http request, parameters and body properties are the http parameters and body of the request";
};

type PATCH record {
    *POSTRequestType;
    "PATCH" 'type = "PATCH";
    string description = "Request type PATCH executes an openflex or salesforce HTTP PATCH request: property service identifies one of the following OF/SF/SO services: identity, selling, gateway, salesforce, srv_opportunity; route is the URI of the http request, parameters and body properties are the http parameters and body of the request";
};

type ManagedPostRequestType record {
    *POSTRequestType;
    ManagedService 'service?;
    string description = "";
};

type ManagedGetRequestType record {
    *GETRequestType;
    ManagedService 'service?;
    string description = "";
};

type ProvidersEntities record {
    // fix me: if one replace RequestType by ManagedPostRequestType then {"type": "ProvidersEntities"} 
    // is no more recognized as this record type like the other manged post request : AuthProvidersSign_in, CreateOpportunity... why ?
    *ManagedPostRequestType;
    ManagedService 'service?;
    "ProvidersEntities" 'type = "ProvidersEntities";
    "/providers/entities" route = "/providers/entities";
    string description = "Request type ProvidersEntities executes openflex POST endpoint /providers/entities";
    string id?;
    string password?;
};

type AuthProvidersSign_in record {
    *ManagedPostRequestType;
    identity 'service = identity;
    "AuthProvidersSign_in" 'type = "AuthProvidersSign_in";
    "/auth/providers/sign-in" route = "/auth/providers/sign-in";
    string entityId;
    string description = "Request type AuthProvidersSign_in executes openflex POST endpoint /auth/providers/sign-in";
    string id?;
    string password?;
};

type AuthUsersSign_in record {
    *ManagedPostRequestType;
    identity 'service = identity;
    "AuthUsersSign_in" 'type = "AuthUsersSign_in";
    "/auth/users/sign-in" route = "/auth/users/sign-in";
    string description = "Request type AuthUsersSign_in executes openflex POST endpoint /auth/users/sign-in";
    string id?;
    string password?;
    string mfaToken?;
};

type AuthProvidersPassword record {
    *ManagedPostRequestType;
    "AuthProvidersPassword" 'type = "AuthProvidersPassword";
    "/auth/providers/password" route = "/auth/providers/password";
    string currentPassword;
    string newPassword;
    string description = "Request type AuthProvidersPassword executes openflex POST endpoint /auth/providers/password";
};

type Users record {
    *ManagedGetRequestType;
    "Users" 'type = "Users";
    "/users" route = "/users";
    string[] pointOfSaleIds;
    string[] groupTypes;
    string description = "Request type Users executes openflex GET endpoint /users, only supported (yet) parameters are pointOfSaleIds and groupTypes";
};

type CreateOpportunity record {
    *SchemedTalk;
    "CreateOpportunity" 'type = "CreateOpportunity";
    map<json> opportunity;
    "/offers" route = "/offers";
    string description = "Schemed talk CreateOpportunity creates an openflex opportunity from its 'opportunity' property (having service opportunity's json format), via the follwing talk scheme: if the SF opportunity has a chassis : executes GET /vehicles/cars?chassis=<chassis> to get the vehicle id and set it in the opportunity json; executes POST /offers with this json; from the reponse with the created OF opportunity ID, executes /opportunities/<OPPORTUNITY_ID>/comments to add the SF opportunity comment to the OF opportunity; then for check purpose : executes /opportunities/<OPPORTUNITY_ID> to check (visually) the content of the created opportunity, then /opportunities/<OPPORTUNITY_ID>/offers to get the ID of the created offer (the last of the returned offer list), then /offers?ids[]=<OFFER_ID> to check (visually) its content";
};

type SFAuth2Token record {
    *ManagedPostRequestType;
    salesforce 'service = salesforce;
    "SFAuth2Token" 'type = "SFAuth2Token";
    "/services/oauth2/token" route = "/services/oauth2/token";
    string description = "Request type SFAuth2Token executes salesforce POST endpoint /services/oauth2/token";
    string username?;
    string password?;
    string client_id?;
    string client_secret?;
};

type SOApiLoginCheck record {
    *ManagedPostRequestType;
    srv_opportunity 'service = srv_opportunity;
    "SOApiLoginCheck" 'type = "SOApiLoginCheck";
    "/api/login_check" route = "/api/login_check";
    string description = "Request type LoginCheck executes service opportunity POST endpoint /api/login_check";
    string username?;
    string password?;
};

type SOApiOpportunities record {
    *ManagedPostRequestType;
    srv_opportunity 'service = srv_opportunity;
    "SOApiOpportunities" 'type = "SOApiOpportunities";
    "/api/opportunities" route = "/api/opportunities";
    string description = "Request type SOApiOpportunities executes service opportunity POST endpoint /api/opportunities";
    map<json> body;
};

type Memorize record {
    *SchemedTalk;
    "Memorize" 'type = "Memorize";
    string description = "Memorize a json value of the last response: the asWhat map property specifies: as the key : the name under which the value is memorized, and as the key value: either the name of the key referencing the value if the reponse is a map, or the index of the value if the response is an array.";
    string|map<string|int> asWhat;
};

type IsSubset record {
    *SchemedTalk;
    "IsSubset" 'type = "IsSubset";
    string description = "If 2nd value of 'values' is a subset of the first value, then executes the 'true' schemedTalks if it/they exist, otherwise the 'false' ones if it/they exist. If there is only one value in 'values', then the last response is taken as the first value. 'true' and 'false' properties are not yet supported and the response is the boolean value of the condition evaluation. If no values are provided teh response is 'No values to compare'";
    json[] values;
    SchemedTalk[] 'true?;
    SchemedTalk[] 'false?;
};

type Equal record {
    *SchemedTalk;
    "Equal" 'type = "Equal";
    string description = "If 2nd value of 'values' is equal to the first value, then executes the 'true' schemedTalks if it/they exist, otherwise the 'false' ones if it/they exist. If there is only one value in 'values', then the last response is taken as the first value. 'true' and 'false' properties are not yet supported and the response is the boolean value of the condition evaluation. If no values are provided teh response is 'No values to compare'";
    json[] values;
    SchemedTalk[] 'true?;
    SchemedTalk[] 'false?;
};

type Sleep record {
    *SchemedTalk;
    "Sleep" 'type = "Sleep";
    string description = "Stops execution for the specified number of seconds. Returns the start and end time of the stoped execution.";
    decimal seconds;
};
