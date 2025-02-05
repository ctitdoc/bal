## Composant ballerina srv_opportunity

Ce composant permet de tester les API des progiciel OpenFlex (OF) et SalesForce (SF) intégrées dans le service opportunity.  
Il contient un module "schemed talks" qui permet de définir et exécuter des schemas (json) de requests/responses entre ces API.

Ce module est executable en CLI ou via un swagger openapi.

### Installation

#### en env de dev local

* ... donc pour faire des chgt de ce composant: 



  
* [installer ballerina](https://ballerina.io/learn/get-started/#install-ballerina);



  
* cloner [le repo](https://github.com/ctitdoc/bal/tree/main) puis cd srv_opportunity;



  
* lancer cette séquence de commande (après avoir renseigné les valeur des credentials):



  




<<<<

    OPENFLEX_TEST_AUTH='{ "FR": { "id": "<login_provider_OF_preprod_FR>", "password": "<password_provider_OF_preprod_FR>" }, "IT": { "id": "<login_provider_OF_preprod_IT>", "password": "<password_provider_OF_preprod_IT>" } }'
    SALESFORCE_TEST_AUTH='{ "username": "<login_api_SF>", "password": "<password_api_SF>","client_id": "<client_id_api_SF>", "client_secret": "<client_secret_api_SF>", "grant_type": "password" }'
    export OPENFLEX_TEST_AUTH
    export SALESFORCE_TEST_AUTH
    bal run -- IT ./SchemedTalks/Empty.json

<<<<

Cette commande fait deux choses:

* elle execute le "schmed talk" vide, qui n'exécute donc aucune request... mais si on le remplace par un qui en contient => cette commande les exécute : mode d'exécution CLI;



  
* elle lance le service http d'exécution de schemed talks => on peut donc aussi les executer via une interface web comme un swagger openapi : voir ci-après;



  
* ... et donc pour arréter cette commande => Ctrl-C ce qui arrête ce service http.



  






#### déployer une release

* ... donc pour intégrer une release de ce composant dans une autre app, par exemple exécutée dans un conteneur docker:



  
* ce composant est écrit en langage Ballerina (langage dédié "intégration de cloud service par API"), qui est un langage compilé produisant une archive java (un fichier .jar).



  
* il faut déployer ballerina dans le conteneur : un package .deb est téléchargeable (lire [installer ballerina](https://ballerina.io/learn/get-started/#install-ballerina)), mais il ne supporte pas les conteneur alpine => il faut déployer la version zippée de Ballerina dans son conteneur : cf le Dockerfile du repo srv_opportunity qui fait ça;



  
* chaque exécution de la commande bal run ci-avant compile l'app ballerina et produit une nouvelle version du .jar dans le repertoire target/bin;



  
* il faut ensuite lancer la commande bal run avec en plus cette archive en paramètre:



  




<<<<



    OPENFLEX_TEST_AUTH='{ "FR": { "id": "<login_provider_OF_preprod_FR>", "password": "<password_provider_OF_preprod_FR>" }, "IT": { "id": "<login_provider_OF_preprod_IT>", "password": "<password_provider_OF_preprod_IT>" } }'
    SALESFORCE_TEST_AUTH='{ "username": "<login_api_SF>", "password": "<password_api_SF>","client_id": "<client_id_api_SF>", "client_secret": "<client_secret_api_SF>", "grant_type": "password" }'
    export OPENFLEX_TEST_AUTH
    export SALESFORCE_TEST_AUTH
    bal run target/bin/-- IT ./SchemedTalks/Empty.json

<<<<

Il faut également avoir les fichier et repertoires suivant présent dans le repetoire d'oû est lancé la commande bal run:

* responses,



  
* SchemedTalks,



  
* Config.toml,



  
* schemed_talk_service_openapi.yaml



  




Voir comme exemple dans le repo srv_opportunity le script tests/deploy_bal_srv_opportunity.sh qui déploie une release dans le repertoire bal_srv_opportunity (lui même recopié dans le conteneur).

... et ce composant utilise les fichier de configuration aws (dans docker/aws-ecs) pour accéder à leur variables d'environnement (comme les URL des APIs OF et SF), il sont donc également à déployer (cf le Dockerfile srv_opportunity comme exemple).

La section getting started détail l'utilisation de ce composant en CLI et via un swagger openapi.





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

NB: ces credentials sont dispos dans bitwarden: OF: "API openflex <env> <country_code>" , SF: "Salesforce <env>" (pas d'API PREPROD SF dispo à date)...  
NB: l'autre endpoint: /schemed_talk_responses retourne les réponses de la dernière exécution de /schemed_talk: il ne sert que dans les environnement avec un timeout configuré trop court par rapport au délais d'exécution du schemed_talk.

