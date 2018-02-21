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
  ' for further details and action.<br>',
  '<bold>Submission UUID:</bold> {{ submission_uuid }}<br>',
  '<bold>Resource UUID:</bold> {{ resource_uuid }}<br>',
  '<bold>Name:</bold> {{ firstName }} {{ lastName }}<br>',
  '<bold>E-mail address:</bold> {{ emailAddress }}<br>',
  '<bold>Organization:</bold> {{ organization }}<br>',
  '<bold>Title:</bold> {{ title }}<br>',
  '<bold>Country:</bold> {{ country }}<br>',
  '<bold>City:</bold> {{ city }}<br>',
];

const textTemplate = [
  'A new resource submission has been received. Please log into ',
  '<a href="https://app.forestadmin.com/">Forest</a>',
  ' for further details and action.\n',
  'Submission UUID: {{ submission_uuid }}\n',
  'Resource UUID: {{ resource_uuid }}',
  'Name: {{ firstName }} {{ lastName }}\n',
  'E-mail address: {{ emailAddress }}\n',
  'Organization: {{ organization }}\n',
  'Title: {{ title }}\n',
  'Country: {{ country }}\n',
  'City: {{ city }}\n',
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