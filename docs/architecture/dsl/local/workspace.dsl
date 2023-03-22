workspace {

    model {
        !include https://raw.githubusercontent.com/ministryofjustice/opg-technical-guidance/main/dsl/poas/persons.dsl
        lpaCaseManagement = softwareSystem "LPA Case Management" "PKA Sirius." "Existing System"
        mrlpaService = softwareSystem "Make and Register an LPA" "Manages Online submissions of LPAs." "Existing System"
        lpaPublicAPI = softwareSystem "LPA Public API" "API Integration for external integration." "Existing System"

        !include lpaidSoftwareSystem.dsl

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
