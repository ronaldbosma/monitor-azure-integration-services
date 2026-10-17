# Environment Overview Dashboard

The Environment Overview dashboard brings the main health and activity signals for the deployed environment together in the Azure portal.

![Environment Overview dashboard](../images/environment-overview-dashboard.png)

The dashboard is defined in [environment-overview-dashboard.bicep](../infra/03-monitoring/modules/environment-overview-dashboard.bicep).

## Open the dashboard

After deploying the template, open [Dashboards](https://portal.azure.com/#dashboard) in the Azure portal and select **Environment Overview - _your-environment-name_** for your `azd` environment. The dashboard is deployed to the environment's resource group.

Set the dashboard's time range to include the activity you want to review. You can also enable auto refresh or refresh the dashboard after generating traffic. Telemetry can take a few minutes to appear.

## Explore the dashboard

The dashboard provides a high-level view of the environment:

- **Availability** and **Avg Health check status** show availability test results and the health reported by the Function App and Logic App.
- **API Management requests** shows request results by API.
- **Open alerts** lists active Azure Monitor alerts in the environment's resource group.
- **Server requests**, **Failed requests**, and **Request duration** show request volume, failures, and latency.
- **Azure Functions** and **Logic App workflows** summarize function executions and workflow runs, including failures.
- **Active messages** and **dead-lettered messages** show Service Bus queue and topic activity.

Some charts and tables may be empty until the corresponding resource has received traffic or generated telemetry.

## Generate activity

Use the [shared testing instructions](./README.md#shared-testing-instructions) to generate traffic to the various Azure Integration Services. To demonstrate failures and alerts, use the relevant [demo scripts](./README.md#demo-scripts).