#!/bin/bash
echo "Create uptime checks for when an endpoint is not triggering data"

#setup the pub/sub topic
echo "Step 1: Setting up pub/sub topic to be configured as log sink"
echo "Creating the topic ..."
gcloud pubsub topics create gchat-topic --project=k8s-app-100

#setup the log sink
echo "Step 2: Setting up the log sink"
echo "Setting up th Sink ..."
gcloud logging sinks create gchat-logsink pubsub.googleapis.com/projects/k8s-app-100/topics/gchat-topic --log-filter 'resource.type = "cloud_run_revision" AND resource.labels.service_name = "prd--oms-service" AND textPayload:"net amount: " AND textPayload:"order number: "'

#Grant permissions on the topic
echo "Step 3: Granting access for Service Account on the topic"
gcloud logging sinks describe gchat-logsink --format='value(writerIdentity)' | sed -E  's/(.*):(.*)/\2/'
gcloud pubsub topics add-iam-policy-binding gchat-topic --member=$(gcloud logging sinks describe gchat-logsink --format='value(writerIdentity)') --role='roles/pubsub.publisher'

#setup cloud-function
echo "Step 3: Setting up the Cloud Function with Google Chat integration"
echo "Creating the Cloud Function ..."
webhookURL="https://example.com/webhook"
gcloud functions deploy demo-function --gen2 --entry-point=pubsubEvent --runtime=nodejs16 --set-env-vars=webhookURL=$webhookURL --trigger-topic=gchat-topic --region=europe-west2

echo "Function and dependent services have been successfully deployed"
