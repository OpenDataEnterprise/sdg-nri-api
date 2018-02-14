#!/usr/bin/env node
'use strict';
require('dotenv').load();

const { deleteContactFormTemplate } = require('./contact-form');
deleteContactFormTemplate();