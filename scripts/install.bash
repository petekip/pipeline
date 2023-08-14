#!/bin/bash
echo "Create message count Gchat alerts to send notifications to GCP Gchat whenever messages go beyond 5 in a Pub/Sub topic"

#setup the pub/sub topic
echo "Step 1: Setting up pub/sub topic to be configured as log sink"
read -p 'Please enter the name for the topic: ' topic
echo "Creating the topic ..."
gcloud pubsub topics create $topic --project=sok-prd-svc

#setup the log sink
echo "Step 2: Setting up the log sink"
read -p 'Please enter the name for the log sink: ' logsink
echo "Setting up th Sink ..."
gcloud logging sinks create $logsink pubsub.googleapis.com/projects/sok-prd-svc/topics/$topic --log-filter 'resource.type="pubsub_subscription" AND resource.labels.project_id="sok-prd-svc" '

#Grant permissions on the topic
echo "Step 3: Granting access for Service Account on the topic"
gcloud logging sinks describe $logsink --format='value(writerIdentity)' | sed -E  's/(.*):(.*)/\2/'
gcloud pubsub topics add-iam-policy-binding $topic --member=$(gcloud logging sinks describe $logsink --format='value(writerIdentity)') --role='roles/pubsub.publisher'

#setup cloud-function //https://chat.googleapis.com/v1/spaces/AAAAsAIL3Nc/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=d_3haLXxWat92MEb82PsK7o3Ipkxgx9d2okOj02ACns%3D
echo "Step 4: Setting up the Cloud Function with Google Chat integration"
read -p 'Enter the name of cloud function: ' cloudfunction
read -p 'Enter the Google Chat webhook URL: ' webhookURL
echo "Creating the Cloud Function ..."
gcloud functions deploy $cloudfunction --gen2 --entry-point=pubsubEvent --runtime=nodejs16 --set-env-vars=webhookURL=$webhookURL --trigger-topic=$topic --region=europe-west2

echo "The Cloud scheduler function and dependent services have been successfully deployed, please be sure to `Allow unauthenticated invocations` in the generated CloudRun service"
