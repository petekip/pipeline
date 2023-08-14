#!/bin/bash
echo "Create uptime checks for when an endpoint is not triggering data"

#setup the pub/sub topic
echo "Step 1: Setting up pub/sub topic to be configured as log sink"
read -p 'Please enter the name for the topic: ' topic
echo "Creating the topic ..."
gcloud pubsub topics create alert-topic --project=k8s-app-100

#setup the log sink
echo "Step 2: Setting up the log sink"
read -p 'Please enter the name for the log sink: ' logsink
echo "Setting up th Sink ..."
gcloud logging sinks create alert-logsink pubsub.googleapis.com/projects/k8s-app-100/topics/alert-topic --log-filter 'resource.type = "cloud_run_revision" AND resource.labels.service_name = "prd--oms-service" AND textPayload:"net amount: " AND textPayload:"order number: "'

#Grant permissions on the topic
echo "Step 3: Granting access for Service Account on the topic"
gcloud logging sinks describe alert-logsink --format='value(writerIdentity)' | sed -E  's/(.*):(.*)/\2/'
gcloud pubsub topics add-iam-policy-binding alert-topic --member=$(gcloud logging sinks describe alert-logsink --format='value(writerIdentity)') --role='roles/pubsub.publisher'

#setup cloud-function
echo "Step 3: Setting up the Cloud Function with Google Chat integration"
read -p 'Enter the name of cloud function: ' cloudfunction
read -p 'Enter the Google Chat webhook URL: ' webhookURL
echo "Creating the Cloud Function ..."
$webhookURL = 'https://chat.googleapis.com/v1/spaces/AAAAsAIL3Nc/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=d_3haLXxWat92MEb82PsK7o3Ipkxgx9d2okOj02ACns%3D';
gcloud functions deploy demo-function --gen2 --entry-point=pubsubEvent --runtime=nodejs16 --set-env-vars=webhookURL=$webhookURL --trigger-topic=alert-topic --region=europe-west2

echo "Function and dependent services have been successfully deployed"
