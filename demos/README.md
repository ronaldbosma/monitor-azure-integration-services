# Monitor Azure Integration Services - Demo

This demo introduces an Azure application that demonstrates ways to monitor Azure Integration Services, including dashboards, workbooks, alerts and health checks.

See the following diagram for an overview of the application:

![Integration Application Overview](../images/integration-application-overview.drawio.png)

See the repository [README](../README.md) for a detailed description of the application.

## 1. What resources are getting deployed

The following resources will be deployed:

![Deployed Resources](../images/deployed-resources.png)

## 2. What can I demo from this scenario after deployment

### Scenarios

The following scenarios are available. Each scenario has its own demo guide with step-by-step instructions. The shared testing instructions below apply to all scenarios.

- [Environment Overview Dashboard](./demo-environment-overview-dashboard.md)

### Shared testing instructions

The application can be explored manually using the REST Client extension in Visual Studio Code, or automatically using the .NET integration tests. The setup below applies to all scenarios.

#### Manual testing using Visual Studio Code

The repository includes [`tests.http`](../tests/tests.http), which contains requests for the Movies and User Ratings APIs.

To send requests using the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension:

1. Install the REST Client extension in Visual Studio Code.
1. Locate the **Built-in all-access** subscription in API Management and copy its primary key.
1. Open the Command Palette (`Ctrl+Shift+P`) and choose `Preferences: Open User Settings (JSON)`.
1. Add an environment to your user settings with the API Management hostname and subscription key. Replace the example key with your own:

   ```json
   "rest-client.environmentVariables": {
       "monitorais": {
           "apimHostname": "apim-monitorais-frc-u7eei.azure-api.net",
           "apimSubscriptionKey": "1234567890abcdefghijklmnopqrstuv"
       }
   }
   ```

1. Open [`tests.http`](../tests/tests.http), then select the `monitorais` environment from the environment selector in the bottom-right corner of the editor.
1. Click **Send Request** above a request to execute it.

The requests are ordered to walk through the APIs: check the health endpoints, list and filter movies, create a movie, retrieve its details and ratings, add a user rating, update the movie and delete it. The create request generates a movie ID that is used by the following requests. A static movie ID is also provided as an alternative. The Logic App recalculates ratings periodically, so rating changes based on user ratings may not appear immediately.

#### Automated integration tests

The repository includes .NET 10 integration tests in [tests/IntegrationTests](../tests/IntegrationTests). The tests use your local `azd` environment variables from `.azure/<environment-name>/.env` to connect to the deployed resources. Make sure the `azd` environment is set to the correct deployment before running the tests.

To run the integration tests from the command line, navigate to the `tests/IntegrationTests` folder and run:

```powershell
dotnet run
```

