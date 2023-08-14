/**
 * Triggered from a log sink message on a Cloud Pub/Sub topic.
 *
 * @param {!Object} event Event payload.
 * @param {!Object} context Metadata for the event.
 */
const fetch = require('node-fetch');

exports.pubsubEvent = (event, context) => {
  //decode and parse the event payload to json	
  //job URL: https://console.cloud.google.com/cloudscheduler/jobs/edit/europe-west2/qa--fs-musoni-integration?project=sok-tst-svc
  const PubSubMessage = event.data;
  const alertData = JSON.parse(Buffer.from(PubSubMessage, 'base64').toString());
  const request = alertData.httpRequest;
  const httpStatus = alertData.httpRequest.status;
  const scheduledTime = alertData.jsonPayload.scheduledTime;
  const payloadStatus = alertData.jsonPayload.status;
  const url = alertData.jsonPayload.url;
  const jobName = alertData.jsonPayload.jobName;
  const targetType = alertData.jsonPayload.targetType;
  const resource = alertData.resource.labels;
  const location = resource.location;
  const job_id = resource.job_id;
  const project = resource.project_id;
  const status =  alertData.severity;
  const timestamp = alertData.timestamp;
  const date = new Date(timestamp); 
  const humanReadableDateTime = date.toLocaleString('en-GB', {dateStyle: 'short', timeStyle: 'short'});// Outputs "4/12/2023, 7:59:00 AM"

  const jobUrl = `https://console.cloud.google.com/cloudscheduler/jobs/edit/${location}/${job_id}?project=${project}`

  //const project ='k8s-app-100';
  const message = `
      *🚨 Scheduler  Alerts <users/all>🚨 ${scheduledTime === undefined ? "Job Finished" : "Job Started"}*
      *📊 Status:* ${httpStatus === 200 || httpStatus === "" ? "🟢 SUCCESS"  : "🔴 ERROR"} ${httpStatus}
      *🆔 Job ID:* ${job_id} 
      *🔗 Job URL:* ${jobUrl}
      *🕰 Job Status:* ${scheduledTime === undefined ? `Job finished at ${humanReadableDateTime}` : `Job started at ${humanReadableDateTime}`}
      *🔢 Status Code:* ${payloadStatus === undefined ? "" : payloadStatus} ${httpStatus}
      *📂 Project:* ${project}
  `;
  
  //Gchat notification using POST
  fetch(process.env.webhookURL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify({
    'text': message,
     })
  }).then((response) => {
    console.log(response);
  });
};