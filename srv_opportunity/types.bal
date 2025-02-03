//examples:
// {"customerId":"1787432","opportunityId":"164","createdAt":null,"updatedAt":"2024-04-16T14:47:36+02:00","deletedAt":null,"id":"511"}
type OpportunityResponse record {
    string opportunityId;
    string id;
};


type VehResponse record {
    int total;
    Veh[] items;
};

type UserResponse record {
    int total;
    User[] items;
};

type User record {
    int id;
    string? email;
    string? firstname;
    string? name;
};

type Veh record {
    int id;
};

type Opportunity record {
    string chassis?;
    json customer;
    json offer;
    AttributedUser|null attributedUser?;
    int|null stockCarId?;
    string|null originalTrackOwner?;
};

type AttributedUser record {
    string? email;
};

type OFOppResponse record {
OFOpp opportunity;
};

type OFOpp record {
    int id;
    int status;
};

type SOOpp record {
    string openflex_opportunity_id;
    string? status;
};

type OFOffer record {
    int id;
};

type OFOffersResponse record {
    OFOffer[] items;
};

type JiraWorkLog record {
    string day;
    string code;
    float hours;
    string ticket;
    string descr;
};

type EntityResponse record {
    Entity[] items;
};

type Entity record {
    int id;
};
