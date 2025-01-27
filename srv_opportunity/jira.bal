import ballerina/http;
import ballerina/io;

public function jira() returns error? {

    io:println("Starting Jira works uploaded...");

    http:Client jiraClient = check new (jiraApiUrl,
        auth = {
            username: jiraUserName,
            password: jiraApiToken
        }
    );

    stream<JiraWorkLog, io:Error?> csvStream = check
                                        io:fileReadCsvAsStream(jiraCsvFilePath);
    // Iterates through the stream and prints the records.
    check csvStream.forEach(function(JiraWorkLog val) {
        io:println(val);

        json body = {
            "comment": {
                "content": [
                    {
                        "content": [
                            {
                                "text": val.code,
                                "type": "text"
                            }
                        ],
                        "type": "paragraph"
                    }
                ],
                "type": "doc",
                "version": 1
            },
            "started": val.day + "T12:00:00.000+0000",
            "timeSpentSeconds": val.hours * 3600
        };

        json|error response =  OFPost(jiraClient, jiraApiUrl, "/rest/api/3/issue/" + val.ticket + "/worklog", body, {});
    });

    io:println("Jira works uploaded !");
}

