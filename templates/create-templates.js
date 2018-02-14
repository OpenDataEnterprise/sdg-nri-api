#!/usr/bin/env node
'use strict';
require('dotenv').load();

const { createContactFormTemplate } = require('./contact-form');
createContactFormTemplate();