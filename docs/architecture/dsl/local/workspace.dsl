workspace {

    model {
        caseWorker = person "Case Worker" "TBC."

        enterprise "Modernising Lasting Power of Attorney" {
            SoftwareSystem = softwareSystem "opg-data-lpa-id" "TBC." {
                webapp = container "Web App" "TBC" "Go, HTML, CSS, JS" "Web Browser"
                app = container "App" "TBC" "Go, API Gateway" "Container" {
                    apiGateway = component "API Gateway" "TBC" "AWS API Gateway" "Component"
                    lambda = component "Generate New ID" "TBC" "AWS Lambda, Go" "Component"
                }
                database = container "Database" "Stores actor information, Draft LPA details, access logs, etc." "DynamoDB" "Database"
            }
        }

        externalSoftwareSystem = softwareSystem "Dummy External Service" "TBC." "Existing System"

        caseWorker -> SoftwareSystem "Uses"

        webapp -> app "Communicates with"
        app -> database "Reads from and writes to"

        apiGateway -> lambda "Communicates with"

        SoftwareSystem -> externalSoftwareSystem "Sends communication with"
    }

    views {
        systemlandscape "SystemLandscape" {
            include *
            autoLayout
        }

        systemContext SoftwareSystem "SystemContext" {
            include *
            autoLayout
        }

        container SoftwareSystem {
            include *
            autoLayout
        }

        component app {
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
