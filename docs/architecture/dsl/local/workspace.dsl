workspace {

    model {
        !include https://raw.githubusercontent.com/ministryofjustice/opg-technical-guidance/main/dsl/poas/persons.dsl
        !include https://raw.githubusercontent.com/ministryofjustice/opg-modernising-lpa/main/docs/architecture/dsl/local/makeRegisterSoftwareSystem.dsl
        !include lpaidSoftwareSystem.dsl
        lpaCaseManagement = softwareSystem "LPA Case Management" "PKA Sirius." "Existing System" {
            -> apiGateway "Makes requests to"
        }
        lpaPublicAPI = softwareSystem "LPA Public API" "API Integration for external integration." "Existing System" {
            -> apiGateway "Makes requests to"
        }

        makeRegisterSoftwareSystem -> apiGateway "Makes requests to"
    }

    views {
        systemContext lpaUIDService "SystemContext" {
            include *
            autoLayout
        }

        container lpaUIDService {
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
