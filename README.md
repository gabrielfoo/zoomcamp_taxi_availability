## Table of Contents

- [Project Overview](#project-overview)
- [Pipeline Overview](#pipeline-overview)
- [Cloud Architecture](#cloud-architecture)
- [Setup Instructions (Windows)](#setup-instructions-windows)
- [Dashboard](#dashboard)
- [License](#license)

## Project Overview

In Singapore, it can be challenging to find taxis in certain areas and at specific times. This project aims to address this issue by analyzing real-time taxi coordinates data. By examining the trends and patterns in taxi availability, we hope to gain insights into the factors contributing to these challenges. Through data visualization, we seek to identify areas and times where taxi shortages are most prevalent, ultimately helping to improve taxi distribution and availability across the city.
## Pipeline Overview

- **Objective**: The overall goal is to gain insights into the distribution and availability of taxis across Singapore in **real-time**, within a **fully cloud-native environment**.
- **Technologies used**:
	- Terraform
	- Kestra
	- Docker
	- Google Cloud Platform:
		- Bigquery
		- Cloud Storage
		- Dataproc Batches (Serverless Apache Spark)
		- Looker Studio
		
0) **Infrastructure**: Terraform initialises the **entire** pipeline in the cloud for a 100% cloud solution.
1) **Orchestration**: Kestra orchestrates the **entire** process, serving as the backbone of the end-to-end pipeline

2) **Data Ingestion**: Taxi coordinates data is scraped every 15 minutes from https://api.data.gov.sg/v1/transport/taxi-availability using a Kestra workflow.

3) **Data Segregation**: The scraped data is programmatically segregated by region. The regions used are North, South, East, West, and North-East, as these divisions are the most meaningful in Singapore.

4) **Table Partitioning**: The segregated data is uploaded to a BigQuery table that is **partitioned by days and clustered by region**. 

5) **Data Transformation**: The data is transformed to aggregate taxi coordinates every 4 hours by region. This step allows for analysis and visualization of where taxis tend to congregate over different time periods.

6) **Data Visualisation:** Dashboard is developed in Looker Studio, with seamless integration with BigQuery tables.

## Cloud Architecture
![image](https://github.com/user-attachments/assets/92f434e6-616c-4f74-ba80-e4e67eae3fb6)

1) Terraform instantiates the entire cloud architecture, which includes the Data Lake, Data Warehouse, and files for Dataproc and Kestra. All files in */flows* are copied and automatically set up the pipeline.
2) The scraped data consists of approximately 2,000 real-time taxi coordinates.
3) Kestra, the orchestrator for this course, controls the entire pipeline from start to  finish. It first scrapes data, then uploads it to a bucket, and triggers Spark to transform the data into BigQuery, where it is then visualized.
4) Kestra outputs data to CSV and uploads it to the Data Lake, a GCP bucket. BigQuery, serving as the data warehouse, acquires data from the Data Lake.
5) Kestra triggers Dataproc (GCP’s Apache Spark) to transform warehouse data by running the script dataproc_wd.py.
6) Kestra also creates two new tables to store the transformed data. The transformed data consists of the taxi locations segregated by time.
## Setup Instructions (Windows)

### Requirements
- **ELEVATED** Windows Command Prompt (I didn't test in Powershell)
- Python 3.X with Requests module installed
- Terraform
- Google Cloud SDK ([Official website](https://cloud.google.com/sdk/docs/install).)

1. **Authenticate Google Cloud SDK in CLI**:
   - Open a command prompt and run the following command to authenticate with your Google account using application-default credentials:
     ```bash
     gcloud auth application-default login
     ```
2. **Create a Project**:
   - Run the following command to create a new project:
     ```bash
     gcloud projects create [PROJECT_ID] && gcloud config set project [PROJECT_ID]
     ```
   - Set and record down [PROJECT_ID]. In the files, i'm using "zoomcamp-uniqueid-1337" as PROJECT_ID, so do a Replace All with your actual project ID.

3. **Enable Billing and APIs**:
   - **IMPORTANT**: Create and link Billing Account to your project: https://console.cloud.google.com/billing/projects
   - Enable the Compute Engine API by executing:
     ```bash
     gcloud services enable compute.googleapis.com
     ```

4. **Create a Service Account**:
   - Create a new service account with:
     ```bash
     gcloud iam service-accounts create [SERVICE_ACCOUNT_NAME] --display-name "Service Account"
     ```
   - Replace `[SERVICE_ACCOUNT_NAME]` with your preferred name.

5. **Assign Roles**:
   - Assign the necessary roles to your service account:
     ```bash
     gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/bigquery.admin"
     gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/compute.networkAdmin"
     gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/dataproc.admin"
     gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/dataproc.serviceAgent"
     gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/dataproc.worker"
     gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/iam.serviceAccountUser"
     gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/storage.admin"
     ```

6. **Create and Download the Key**:
   - Use the following command to create a key for the service account and download it as a JSON file:
     ```bash
     gcloud iam service-accounts keys create [FILE_NAME].json --iam-account [SERVICE_ACCOUNT_NAME]@[PROJECT_ID].iam.gserviceaccount.com
     ```
   - Replace `[FILE_NAME].json` with the desired name for your JSON key file.
   
7. Replace Service Account JSON in kestra/flows/gcp_kv.yml at where it says "---INSERT SERVICE ACCOUNT JSON HERE---".
   
8. **Initialize and Apply Terraform**:
   - Navigate to your Terraform configuration directory and execute the following commands:
     ```bash
     terraform init
     terraform apply
     ```

9. **Done!** Kestra pipeline is set to run automatically. Login using the username and password defined in application.yaml and variables.tf (should be the same). Check BigQuery dataset for output.

## Dashboard
![image](https://github.com/user-attachments/assets/322935e9-2e83-45de-9fab-82e12e8f212e)

[Dashboard Link](https://lookerstudio.google.com/u/0/reporting/2933441c-ca35-4991-a2dd-983169fd7ecd)

The dashboard provides a comprehensive view of taxi data in Singapore, split into two distinct sections for ease of analysis:

- **Left Half: Real-Time Data Visualization**
  - **Map Display**: Shows raw real-time taxi coordinates on a map.
  - **Time Filtering**: Includes a dropdown list to filter the data by specific time intervals.
  - **Pie Chart**: Displays the percentage and number of taxis in each region, allowing for a quick overview of taxi distribution across Singapore.

- **Right Half: Historical Data Analysis**
  - **Weekday and Weekend Graphs**: Transforms raw data into separate graphs for the past 5 weekdays and 2 weekends, respectively.
  - **Time Binning**: Data is organized into time bins of every 4 hours, providing insights into taxi activity throughout the day.
  - **Regional Segregation**: Each time bin is further segregated by region, helping identify patterns in taxi distribution across different areas of the city.

This dashboard enables users to explore both current and historical trends in taxi availability, offering valuable insights into regional and temporal patterns.

## License
MIT License
