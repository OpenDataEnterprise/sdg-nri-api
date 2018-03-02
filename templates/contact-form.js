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

const templateName = 'ContactFormTemplate';

const htmlTemplate = [
  '<b>Name:</b> {{ firstName }} {{ lastName }}<br>',
  '<b>E-mail address:</b> {{ emailAddress }}<br>',
  '<b>Organization:</b> {{ organization }}<br>',
  '<b>Title:</b> {{ title }}<br>',
  '<b>Country:</b> {{ country }}<br>',
  '<b>City:</b> {{ city }}<br>',
  '<b>Message:</b> {{ message }}<br>',
  '<b>I am interested in:</b> {{ interests }}',
];

const textTemplate = [
  'Name: {{ firstName }} {{ lastName }}\n',
  'E-mail address: {{ emailAddress }}\n',
  'Organization: {{ organization }}\n',
  'Title: {{ title }}\n',
  'Country: {{ country }}\n',
  'City: {{ city }}\n',
  'Message: {{ message }}\n',
  'I am interested in: {{ interests }}',
];

const contactFormTemplate = {
  'Template': {
    'TemplateName': templateName,
    'SubjectPart': 'Form Submission - SDG National Reporting Initiative Contact Form',
    'HtmlPart': htmlTemplate.join(''),
    'TextPart': textTemplate.join(''),
  },
};

function createContactFormTemplate() {
  var createPromise = new AWS.SES(AWSConfig).createTemplate(contactFormTemplate).promise();

  createPromise.then(function(data) {
    console.log(data.MessageId);
  }).catch(function(err) {
    console.error(err);
  });
}

function deleteContactFormTemplate() {
  var deletePromise = new AWS.SES(AWSConfig).deleteTemplate({
    TemplateName: templateName
  }).promise();

  deletePromise.then(function(data) {
    console.log(data.MessageId);
  }).catch(function(err) {
    console.error(err);
  });
}

exports.contactFormTemplate = contactFormTemplate;
exports.createContactFormTemplate = createContactFormTemplate;
exports.deleteContactFormTemplate = deleteContactFormTemplate;
