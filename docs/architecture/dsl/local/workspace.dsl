workspace {

    model {
        caseWorker = person "Case Worker (Frontend)" "Case worker creating new cases for the Paper journey."
        donor = person "Donor" "Donors creating a new LPA on the MRLPA service."
        publicActor = person "Public Actors (API)" "Users integrating with LPAs such as Solicitors and Charities via an API."

        lpaCaseManagement = softwareSystem "LPA Case Management" "PKA Sirius." "Existing System"
        mrlpaService = softwareSystem "Make and Register an LPA" "Manages Online submissions of LPAs." "Existing System"
        lpaPublicAPI = softwareSystem "LPA Public API" "API Integration for external integration." "Existing System"

        !include lpaidSoftwareSystem.dsl

        caseWorker -> lpaCaseManagement "Uses"
        donor -> mrlpaService "Uses"
        publicActor -> lpaPublicAPI "Uses"

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
