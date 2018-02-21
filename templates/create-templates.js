#!/usr/bin/env node
'use strict';
require('dotenv').load();

const { createContactFormTemplate } = require('./contact-form');
const { createResourceFormTemplate } = require('./resource-form');

createContactFormTemplate();
createResourceFormTemplate();