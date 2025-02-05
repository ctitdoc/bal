## Composant ballerina srv_opportunity

Ce composant permet de tester les API des progiciel OpenFlex (OF) et SalesForce (SF) intégrées dans le service opportunity.  
Il contient un module "schemed talks" qui permet de définir et exécuter des schemas (json) de requests/responses entre ces API.

Ce module est executable en CLI ou via un swagger openapi.

### Installation

To Be Completed ...



### Getting Started

1. Définir un schéma de request :

    1. prendre exemple sur ceux dans le répertoire SchemedTalk : SchemedTalks.json, GET.json, POST.json...

        * chaque map json dans ces fichier décrit une request dont le type est définie par la champ "type": 

            * SchemedTalks.json contient des types de request prédéfinies:

                * ProvidersEntities décrit une request OF POST /providers/entities (voir le swagger OF qui définit cette request;



  
                * toutes les requetes prédéfinies sont définies via leur type correspondant dans le fichier schemed_talk_type.bal;



  
                * le type de la request est sa route en notation CamelCase: /providers/entities => ProvidersEntities;



  
                * la propriété "type" de ce type ProvidersEntities est une copie de celui-ci, et le type de cette propriété est limité à la seule string "ProvidersEntities" (voir la doc ballerina sur les types): la conséquence est que ballerina sait caster automatiquement un contenu json { "type":"ProvidersEntities" ... } en une valeur de ce type et faire au passage les controles de validation de type de ses propriétés (id, password...);



  
                * les paramètres et body de la request sont définies comme des propriétés de ce type: id et password constituent le body de la request /providers/entities : { "id":"<id>", "password":"<password>"};



  






  
            * GET.json et POST.json sont des exemples de request GET et POST (cf la définition de leur type dans ce même fichier);



  
            * le but est d'ajouter au fil du temps à ce composant, des types prédéfinis pour les request déjà testées, et d'utiliser GET et POST pour les test de nouvelles request.



  






  
        * évolution majeure à venir:

            * définir des requests qui sont composées d'autres requests et dont les données peuvent être issues des données des responses précédentes via requétage/transformation de ces données: le nom donné a de telles requests est ... "schemed talk" ... d'oû le nom du module.



  






  






  






  
2. Exécuter le schéma:

    * pour exécuter le schéma en CLI sur le pays IT: exécuter à la racine du module:

        * bal run -- IT <le_fichier_du_schéma>



  
        * les responses aux requests exécutées sont affichées dans la console;



  
        * cette commande lance également le service http de ce composant, donc pour l'arréter faire un Ctrl-C;



  






  
    * pour éxécuter le schéma via les swagger openapi disponibles avec ce composant:

        1. après avoir lancé la comande CLI ci-avant:



  
        2. dézipper là oû on veut l'archive [swagger-ui](https://github.com/swagger-api/swagger-ui) : tools/swagger-ui-<version>.zip,



  
        3. ouvrir dans un browser le fichier swagger-ui-<version>/dist/index.html,



  
        4. cela affiche le swagger pré-configuré pour envoyer les request au endpoint /schemed_talk du service http de ce composant,



  
        5. la différence avec la version CLI est que pour les request d'authentification aux API OF et SF, il faut passer les paramètres d'authentification dans les request envoyées:



  






  






  




Pour OF:

<<<<

    Pour OpenFlex:
    
        {
         "type": "ProvidersEntities",
         "id": "XXXX",
         "password": "XXXX"
        },
    
    
    {
        "type": "AuthProvidersSign_in",
        "entityId": "XXXX",
         "id": "XXXX",
         "password": "XXXX"
    },
    
    Pour SalesForce:
    
        {
            "type": "SFAuthToken",
            "username": "XXXX",
            "password": "XXXX",
            "client_id": "XXXX",
            "client_secret": "XXXX"
        }

<<<<

NB: l'autre endpoint: /schemed_talk_responses retourne les réponses de la dernière exécution de /schemed_talk: il ne sert que dans les environnement avec un timeout configuré trop court par rapport au délais d'exécution du schemed_talk.



