workspace {

    model {
        caseWorker = person "Case Worker (Frontend)" "Case worker creating new cases for the Paper journey."
        donor = person "Donor" "Donors creating a new LPA on the MRLPA service."
        publicActor = person "Public Actors (API)" "Users integrating with LPAs such as Solicitors and Charities via an API."

        lpaCaseManagement = softwareSystem "LPA Case Management" "PKA Sirius." "Existing System"
        mrlpaService = softwareSystem "Make and Register an LPA" "Manages Online submissions of LPAs." "Existing System"
        lpaPublicAPI = softwareSystem "LPA Public API" "API Integration for external integration." "Existing System"

        enterprise "LPA ID Service" {
            lpaIDService = softwareSystem "LPA ID Service" "Generates IDs and stores donor details." {
                iam = container "IAM" "Manages permissions to API Gateway" "AWS IAM" "Component"
                certificateManager = container "Certificate Manager" "Generate a valid cert for SSL connectivity to the API" "AWS Certificate Manager" "Component"
                dns = container "DNS" "Generate a friendly DNS Name for the API" "AWS Route 53" "Component"
                apiGateway = container "API Gateway" "Provides a REST API for communication to the service." "AWS API Gateway v2, OpenAPI" "Component"
                lambda = container "Lambda" "Executes code for generating and returning new LPA ID" "AWS Lambda, Go" "Component"
                database = container "Database" "Stores LPA IDs." "DynamoDB" "Database"
            }
        }

        caseWorker -> lpaCaseManagement "Uses"
        donor -> mrlpaService "Uses"
        publicActor -> lpaPublicAPI "Uses"

        apiGateway -> lambda "Forwards requests to and Returns responses from"
        apiGateway -> iam "Validates requests"
        lambda -> database "Queries and writes to"

        lpaCaseManagement -> apiGateway "Makes requests to"
        mrlpaService -> apiGateway "Makes requests to"
        lpaPublicAPI -> apiGateway "Makes requests to"
    }

    views {
        systemlandscape "SystemLandscape" {
            include *
            autoLayout
        }

        systemContext lpaIDService "SystemContext" {
            include *
            autoLayout
        }

        container lpaIDService {
            include *
            autoLayout
        }

        theme default

        styles {
            element "Existing System" {
                background #999999
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
        }
    }
}
