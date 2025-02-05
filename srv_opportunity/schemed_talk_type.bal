
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

public enum OFService {identity, selling, gateway, salesforce};

type RequestType record {
    *SchemedTalk;
    OFService 'service;
    string 'type = "Request";
    string route?;
};

type GETRequestType record {
    *RequestType;
    string 'type = "GET";
    map<string|int|float|boolean|(string|int|float|boolean)[]>? parameters?;
};

type GET record {
    *GETRequestType;
    "GET" 'type = "GET";
    string description = "Request type GET executes an openflex or salesforce HTTP GET request: property service identifies one of the following OF/SF services: identity, selling, gateway, salesforce; route is the URI of the http request, parameters property are the http parameters and body of the request";
};

type POSTRequestType record {
    *GETRequestType;
    string 'type = "POST";
    json body?;
};


type POST record {
    *POSTRequestType;
    "POST" 'type = "POST";
    string description = "Request type POST executes an openflex or salesforce HTTP POST request: property service identifies one of the following OF/SF services: identity, selling, gateway, salesforce; route is the URI of the http request, parameters and body properties are the http parameters and body of the request";
};

type ManagedPostRequestType record {
    *POSTRequestType;
    OFService 'service?;
    string description = "";
};

type ManagedGetRequestType record {
    *GETRequestType;
    OFService 'service?;
    string description = "";
};

type ProvidersEntities record  {
    // fix me: if one replace RequestType by ManagedPostRequestType then {"type": "ProvidersEntities"} 
    // is no more recognized as this record type like the other manged post request : AuthProvidersSign_in, CreateOpportunity... why ?
    *ManagedPostRequestType;
    OFService 'service?;
    "ProvidersEntities" 'type = "ProvidersEntities";
    "/providers/entities" route = "/providers/entities";
    string description = "Request type ProvidersEntities executes openflex POST endpoint /providers/entities";
    string id?;
    string password?;
};

type AuthProvidersSign_in record  {
    *ManagedPostRequestType;
    OFService 'service?;
    "AuthProvidersSign_in" 'type = "AuthProvidersSign_in";
    "/auth/providers/sign-in" route = "/auth/providers/sign-in";
    string entityId;
    string description = "Request type AuthProvidersSign_in executes openflex POST endpoint /auth/providers/sign-in";
    string id?;
    string password?;
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

type SFAuthToken record  {
    // fix me: if one replace RequestType by ManagedPostRequestType then {"type": "ProvidersEntities"} 
    // is no more recognized as this record type like the other manged post request : AuthProvidersSign_in, CreateOpportunity... why ?
    *ManagedPostRequestType;
    OFService 'service?;
    "SFAuthToken" 'type = "SFAuthToken";
    "/services/oauth2/token" route = "/services/oauth2/token";
    string description = "Request type SFAuthToken executes salesforce POST endpoint /services/oauth2/token";
    string username?;
    string password?;
    string client_id?;
    string client_secret?;
};
