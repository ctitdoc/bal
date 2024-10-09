import ballerina/io;

//see https://ballerina.io/learn/by-example/configuring-via-toml
configurable string projectDir = ?;
configurable string jsonConfigFile = ?;
configurable string balDir = ?;
configurable string[] scenarios = ?;
//OF = OpenFlex
configurable string OFAuthJson = ?;
//Jira
configurable string jiraApiUrl = ?;
configurable string jiraApiToken = ?;
configurable string jiraUserName = ?;
configurable string jiraCsvFilePath = ?;

public function getConf() returns json|io:Error {
    return io:fileReadJson(projectDir + "/" + jsonConfigFile);
}

type envVar record {
    string name;
    string value;
};

type containerConf record {
    string name;
    envVar[] environment;
};

type Conf record {
    containerConf[] containerDefinitions;
};

public function getContainerEnvVar(json jsonConf, string containerName, string envVarName) returns string|error {
    Conf|error conf = jsonConf.cloneWithType();
    if (conf is error) {
        return conf;
    } else {
        envVar[][] envs = from containerConf c in conf.containerDefinitions
        where c.name == containerName
         limit 1
         select c.environment;

        string|error enVarValue = from var envVar in envs[0]
         where envVar.name == envVarName
         limit 1
         select envVar["value"];
   
         return enVarValue;
    }
}

  public function getBalDir() returns string {
    return projectDir + "/" + balDir;
 }

 public function getJsonOFAuthCredentials() returns json|io:Error {
    return io:fileReadJson(getBalDir() + "/" + OFAuthJson);
 }

  public function getJson(string jsonFileName) returns json|io:Error {
    return io:fileReadJson(getBalDir() + "/" + jsonFileName);
 }
 