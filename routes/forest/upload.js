'use strict';
const express = require('express');
const router = express.Router();
const liana = require('forest-express-sequelize');
const AWS = require('aws-sdk');

function detectBase64MimeType (data) {
  let mimeType = null;

  if (typeof data === 'string') {
    mimeType = data.split(';')[0].split(':')[1];
  }

  return mimeType;
}

function uploadImage (req, res, next) {
  const resourceUUID = req.body.data.id;
  const rawData = req.body.data.attributes.image_url;

  // Skip processing if no image data is given.
  if (!rawData) {
    return next();
  }

  // Parse the data "URL" scheme (RFC 2397).
  const mimeType = detectBase64MimeType(rawData);
  const base64Image = rawData.replace(/^data:image\/\w+;base64,/, '');

  var data = {
    Key: resourceUUID,
    Body: Buffer.from(base64Image, 'base64'),
    ContentEncoding: 'base64',
    ContentType: mimeType,
    ACL: 'public-read'
  };

  const AWSConfig = {
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    },
    region: process.env.AWS_REGION,
    params: { Bucket: process.env.S3_BUCKET }
  };

  // Create the S3 client.
  const s3Bucket = new AWS.S3(AWSConfig);

  // Upload the image.
  s3Bucket.upload(data, function (error, data) {
     if (error) { return next(error); }

     // Inject the new image URL to the params.
     req.body.data.attributes.image_url = data.Location;

     // Finally, call the default PUT behavior.
     next();
  });
}

router.put('/resource/:resourceId', liana.ensureAuthenticated, uploadImage);

module.exports = router;
