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
  '<span>Contact Form:</span>',
  '<ul>',
  '<li>Name: {{ firstName }} {{ lastName }}</li>',
  '<li>E-mail address: {{ emailAddress }}</li>',
  '<li>Organization: {{ organization }}</li>',
  '<li>Title: {{ title }}</li>',
  '<li>Country: {{ country }}</li>',
  '<li>City: {{ city }}</li>',
  '<li>Message: {{ message }}</li>',
  '<li>Interests: {{ interests }}</li>',
  '</ul>',
];

const textTemplate = [];

const contactFormTemplate = {
  'Template': {
    'TemplateName': templateName,
    'SubjectPart': 'New SDG NRI Website Contact Form Submission',
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