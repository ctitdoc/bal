import ballerina/io;

public function main(string countryCode = "IT", string schemedTalkUri = "./SchemedTalks/SchemedTalk.json") returns error? {
    
    io:println("srv opportunity API calls tests");
    io:println("usage:");
    io:println("OPENFLEX_TEST_AUTH='{ (\"env\": \"prod\")?, (\"<country_code>\": { \"id\": \"<api_login>\", \"password\": \"<api_password>\" },)+  }' bal run -- <country_code> <schemed_talk_file>?");
    io:println("env entry in OPENFLEX_TEST_AUTH is between ()? because optional, as openflex env is set by default to preprod, but you can set it to prod in it;");
    io:println("<country_code> entry is between ()+ bcause there should be at leats one:");
    io:println("copy/paste it from OPENFLEX_AUTH env variable of the target env, replace login by id, and you're done.");
    io:println("bal should be executed from the ballerina srv_opportunity root dir (in tests/bal/srv_opportunity)");
    io:println("schemed_talk_file is optional and default to SchemedTalks/SchemedTalk.json, but one can create others (take this one as an example, or the more simple SchemedTalks/Users.json).");
    io:println("NB: for multiple runs with the same OPENFLEX_TEST_AUTH, run them like that:");
    io:println("OPENFLEX_TEST_AUTH='{...}'");
    io:println("export OPENFLEX_TEST_AUTH");
    io:println("bal run IT");
    io:println("bal run FR");
    io:println("...");
    io:println();
    io:println();
    io:println(string `... executing schemed talk: ${schemedTalkUri} ...`);

    json schemedTalkJson = check io:fileReadJson(schemedTalkUri);
    SchemedTalk[] schemedTalks = check schemedTalkJson.cloneWithType();
    
    json response = check process(schemedTalks, countryCode);

    if (play("oppStatus")) {
        var db_srv_opportunity = check getDbClient();
        SOOpp[] opps = getOpportunities(db_srv_opportunity);
        io:println(opps);
    }

    if (play("jira")) {
        check jira();
    }
}
