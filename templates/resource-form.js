'use strict';
var exports = module.exports = {};

const AWS = require('aws-sdk');
const AWSConfig = {
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  },
  region: process.env.AWS_REGION,
  apiVersion: '2010-12-01',
};

const templateName = 'ResourceFormTemplate';

const htmlTemplate = [
  'A new resource submission has been received. Please log into ',
  '<a href="https://app.forestadmin.com/">Forest</a>',
  ' for further details and action.<br><br>',
  '<h1>Submitted Resource Information</h1>',
  '<b>Resource UUID:</b> {{ resourceUUID }}<br>',
  '<b>Title:</b> {{ resourceTitle }}<br>',
  '<b>Organization:</b> {{ resourceOrganization }}<br>',
  '<b>URL:</b> {{ resourceURL }}<br>',
  '<b>Description:</b> {{ resourceDescription }}<br>',
  '<b>Tags:</b> {{ resourceTags }}<br>',
  '<b>Additional Information:</b> {{ additionalInfo }}<br><br>',
  '<h1>Submitter Information</h1>',
  '<b>Submission UUID:</b> {{ submissionUUID }}<br>',
  '<b>Name:</b> {{ firstName }} {{ lastName }}<br>',
  '<b>E-mail address:</b> {{ emailAddress }}<br>',
  '<b>Organization:</b> {{ organization }}<br>',
  '<b>Title:</b> {{ title }}<br>',
  '<b>Country:</b> {{ country }}<br>',
  '<b>City:</b> {{ city }}',
];

const textTemplate = [
  'A new resource submission has been received. Please log into ',
  '<a href="https://app.forestadmin.com/">Forest</a>',
  ' for further details and action.\n\n',
  'Submitted Resource Information\n',
  '----------\n',
  'Resource UUID: {{ resourceUUID }}\n',
  'Title: {{ resourceTitle }}\n',
  'Organization: {{ resourceOrganization }}\n',
  'URL: {{ resourceURL }}\n',
  'Description: {{ resourceDescription }}\n',
  'Tags: {{ resourceTags }}\n',
  'Additional Information: {{ additionalInfo }}\n\n',
  'Submitter Information\n',
  '----------\n',
  'Submission UUID: {{ submissionUUID }}\n',
  'Name: {{ firstName }} {{ lastName }}\n',
  'E-mail address: {{ emailAddress }}\n',
  'Organization: {{ organization }}\n',
  'Title: {{ title }}\n',
  'Country: {{ country }}\n',
  'City: {{ city }}',
];

const resourceFormTemplate = {
  'Template': {
    'TemplateName': templateName,
    'SubjectPart': 'Form Submission - SDG National Reporting Initiative Resource Submission Form',
    'HtmlPart': htmlTemplate.join(''),
    'TextPart': textTemplate.join(''),
  },
};

function createResourceFormTemplate() {
  var createPromise = new AWS.SES(AWSConfig).createTemplate(resourceFormTemplate).promise();

  createPromise.then(function(data) {
    console.log(data.MessageId);
  }).catch(function(err) {
    console.error(err);
  });
}

function deleteResourceFormTemplate() {
  var deletePromise = new AWS.SES(AWSConfig).deleteTemplate({
    TemplateName: templateName
  }).promise();

  deletePromise.then(function(data) {
    console.log(data.MessageId);
  }).catch(function(err) {
    console.error(err);
  });
}

exports.resourceFormTemplate = resourceFormTemplate;
exports.createResourceFormTemplate = createResourceFormTemplate;
exports.deleteResourceFormTemplate = deleteResourceFormTemplate;
