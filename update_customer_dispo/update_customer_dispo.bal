import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/task;

// === CONFIG STRUCTURES ===

type AlgoliaConf record {
    string appId;
    string apiKey;
    string indexName;
};

type TeamsConf record {
    string webhookUrl;
    string channelId;
    string apiKey;
};

type CustomerDispoConf record {
    boolean dryRun;
    boolean dryRunNotify;
};

// === CONFIGURABLE VALUES ===

configurable AlgoliaConf algolia = ?;
configurable TeamsConf teams = ?;
configurable CustomerDispoConf customerDispo = ?;

const int BATCH_SIZE = 10000;
const string STATE_FILE = "last_customerDispo_update.txt";

// === STATE FILE ===

function getLastRunTimestamp() returns string?|error {
    boolean readable = false;
    do {
        readable = check file:test(STATE_FILE, file:EXISTS) && check file:test(STATE_FILE, file:READABLE);
    } on fail {
        readable = false;
    }
    if readable {
        return check io:fileReadString(STATE_FILE);
    }
    return ();
}

function saveTimestamp(string ts) returns error? {
    check io:fileWriteString(STATE_FILE, ts);
}

// === SCHEDULER INITIALISATION ===
public function main() returns error? {
    Job myJob = new (algolia, teams, customerDispo);
    task:JobId _ = check task:scheduleJobRecurByFrequency(myJob, 60);
}

class Job {
    *task:Job;
    AlgoliaConf algolia;
    TeamsConf teams;
    CustomerDispoConf customerDispo;
    string algoliaUrl;
    map<string> headers;
    map<string> headersTeams;

    function init(AlgoliaConf algoliaConf, TeamsConf teamsConf, CustomerDispoConf dispoConf) {
        self.algolia = algoliaConf;
        self.teams = teamsConf;
        self.customerDispo = dispoConf;
        self.algoliaUrl = "https://" + self.algolia.appId + "-dsn.algolia.net";
        self.headers = {
            "X-Algolia-API-Key": self.algolia.apiKey,
            "X-Algolia-Application-Id": self.algolia.appId,
            "Content-Type": "application/json"
        };
        self.headersTeams = {
            "x-api-key": self.teams.apiKey,
            "X-Algolia-Application-Id": self.algolia.appId
        };

    }

    // === SCHEDULED EXECUTION FUNCTIONS ===
    public function execute() {
        do {
            log:printInfo("⏱️ Job planifié : exécution de scheduledRun()");
            var result = self.scheduledRun();
            if result is error {
                string msg = "❌ scheduledRun() a échoué : " + result.message();
                log:printError(msg, result);
                // Envoi d'une notification Teams en cas d'erreur
                var notif = self.sendTeamsNotification("Erreur exécution customerDispo", msg, [{"Type d'exécution": "Tâche planifiée"}]);
                if notif is error {
                    log:printError("Échec d'envoi Teams", notif);
                }
            }
        } on fail var failure {
            log:printError("Unmanaged error", failure);
        }
    }

    function scheduledRun() returns error? {
        http:Client algoliaClient = check new (self.algoliaUrl);
        string? lastRun = check getLastRunTimestamp();
        log:printInfo("Last run timestamp: " + (lastRun ?: "none"));

        map<json> logData = check algoliaClient->get("/1/logs?length=" + BATCH_SIZE.toString() + "&type=update", self.headers);
        //map<json> logData = check (check logRes.getJsonPayload()).cloneWithType();
        json logsJson = logData["logs"];
        string? latestMoveTimestamp = ();
        if logsJson is json[] {
            map<json>[] logs = check logsJson.cloneWithType();
            foreach map<json> logEntry in logs {
                (string|error)? queryString = logEntry["query_body"].cloneWithType();
                (json|error)? query = ();
                if queryString is string {
                    query = queryString.fromJsonString();
                }
                if query is map<json> && query["operation"] is string && query["operation"] == "move"
                && query["destination"] is string && query["destination"] == self.algolia.indexName
                {
                    string ts = "";
                    if logEntry["timestamp"] is string {
                        ts = check logEntry["timestamp"].cloneWithType();
                    }
                    if latestMoveTimestamp is () || ts > latestMoveTimestamp {
                        latestMoveTimestamp = ts;
                    }
                }
            }

            if latestMoveTimestamp is () {
                log:printInfo("No move detected.");
                return;
            }

            log:printInfo("Latest move detected at: " + latestMoveTimestamp);

            if lastRun is () || latestMoveTimestamp > lastRun {
                log:printInfo("Triggering customerDispo update (dryRun=" + self.customerDispo.dryRun.toString() + ")...");
                var result = self.updateCustomerDispo(algoliaClient);
                if (result is error) {
                    string errMsg = "Erreur lors de l'update customerDispo: " + result.message();
                    log:printError(errMsg);
                    // Envoi de notification Teams pour l'erreur
                    check self.sendTeamsNotification("Erreur Update customerDispo", errMsg, [{"Algolia index": self.algolia.indexName}]);
                } else {
                    log:printInfo("Mise à jour customerDispo effectuée avec succès.");
                }
                if !self.customerDispo.dryRun {
                    check saveTimestamp(latestMoveTimestamp);
                }
            } else {
                log:printInfo("No update needed.");
            }
        } else {
            return error("Expected logs to be an array");
        }

    }

    // === CUSTOMER DISPO BUSNESS LOGIC FUNTION ===
    public function updateCustomerDispo(http:Client algoliaClient) returns error? {
        string cursor = "";
        boolean hasMore = true;
        int totalUpdated = 0;

        while hasMore {
            string url = "/1/indexes/" + self.algolia.indexName + "/browse";
            if cursor != "" {
                url += "?cursor=" + cursor;
            }

            http:Response res = check algoliaClient->get(url, self.headers);
            map<json> body = check (check res.getJsonPayload()).cloneWithType();

            json[] hits;
            if body["hits"] is json[] {
                hits = check body["hits"].cloneWithType();
                log:printInfo("retrieved " + hits.length().toString() + " offers...");
            } else {
                return error("Expected hits to be an array");
            }

            string cursorVal = "";
            if body["cursor"] is string {
                cursorVal = check body["cursor"].cloneWithType();
            }
            log:printInfo("cursor value is: " + cursorVal);
            cursor = cursorVal;
            hasMore = cursor != "null" && cursor.length() > 0;

            json[] updates = [];

            foreach json hit in hits {
                string id = "";
                int? nature = ();
                string dispo = "";
                if hit is map<json>
                {
                    if hit["objectID"] is string {
                        id = check hit["objectID"].cloneWithType();
                    }
                    if hit["nature"] is int {
                        nature = check hit["nature"].cloneWithType();
                    }
                    if hit["disponibiliteForFO"] is string {
                        dispo = check hit["disponibiliteForFO"].cloneWithType();
                    }
                }
                if id == "" || dispo == "" { // for update test on a single offre, add this condition with a proper offer id: || id != "240314"
                    continue;
                }

                string customerDispoValue = (nature != 1 && nature != 5 && dispo == "en stock") ? "disponible" : dispo;

                json update = {
                    action: "partialUpdateObject",
                    body: {
                        objectID: id,
                        customerDispo: customerDispoValue
                    }
                };
                updates.push(update);
            }

            if updates.length() > 0 {
                if !self.customerDispo.dryRun {
                    json batchPayload = {requests: updates};
                    http:Response batchRes = check algoliaClient->post("/1/indexes/" + self.algolia.indexName + "/batch", batchPayload, self.headers);
                    log:printInfo("Updated " + updates.length().toString() + " records.");
                } else {
                    log:printInfo("Dry-run: simulated update of " + updates.length().toString() + " records.");
                }
                totalUpdated += updates.length();
            }

            runtime:sleep(1);
        }

        log:printInfo("customerDispo update finished.");

        if self.customerDispo.dryRun && self.customerDispo.dryRunNotify {
            string msg = "**[Dry-run OK]** Mise à jour customerDispo simulée sur " + totalUpdated.toString() + " enregistrements.";
            check self.sendTeamsNotification("Update customer dispo dry-run", msg, [{"Algolia index": self.algolia.indexName}]);
        }
    }

    // === TEAMS NOTIF ===
    function sendTeamsNotification(string title, string description, map<string>[] list) returns error? {
        http:Client teamsClient = check new (self.teams.webhookUrl);
        json payload = {
            title: title,
            description: description,
            channel_id: self.teams.channelId,
            list: []
        };

        // Envoi réel de la notification via POST
        http:Response response = check teamsClient->post("", payload, self.headersTeams);
        int statusCode = response.statusCode;
        if (statusCode != 200) {
            string content = check response.getTextPayload();
            log:printError("Échec de notification Teams. Code: " + statusCode.toString() + ", Message: " + content);
        } else {
            log:printInfo("Notification Teams envoyée avec succès.");
        }
    }

}

// === WORKAROUND SERVICE (WILL BECOME A JOBS ADMIN SERVICE) ===
service http:Service / on new http:Listener(9876) {
resource function get health() returns string {
       return "this is a workaround to keep the script live sothat the secheduled job can run...";
    }
}

