'use strict';
const express = require('express');
const router = express.Router();
const { check, validationResult } = require('express-validator/check');
const { matchedData, sanitizeBody } = require('express-validator/filter');
const squel = require('squel');
const models = require('../../../models');
const sequelize = models.sequelize;
const AWS = require('aws-sdk');
const { contactFormTemplate } = require('../../../templates/contact-form');

const AWSConfig = {
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  },
  region: process.env.AWS_REGION,
  apiVersion: '2010-12-01',
};

const errorRedirectURL = (process.env.SITE_URL + '/error')
  // Remove duplicate forward slashes.
  .replace(/([^:]\/)\/+/g, "$1");

router.get('/', (req, res) => {
  try {
    res.status(200).send();
  } catch (err) {
    handleError(err);
  }
});

router.post('/contact-form', async (req, res, next) => {
  try {
    // Sanitize form inputs.
    sanitizeBody('first-name').stripLow().trim().escape();
    sanitizeBody('last-name').stripLow().trim().escape();
    sanitizeBody('email').normalizeEmail();
    sanitizeBody('organization').stripLow().trim().escape();
    sanitizeBody('title').stripLow().trim().escape();
    sanitizeBody('country').stripLow().trim().escape();
    sanitizeBody('city').stripLow().trim().escape();
    sanitizeBody('message').stripLow().trim().escape();
    sanitizeBody('interests.*').stripLow().trim().escape();

    // Handle empty array (i.e. checkboxes not selected).
    // Must give at least a default value or else e-mail alerts will not send.
    req.body['interests'] = (typeof req.body['interests'] !== 'undefined')
        ? req.body['interests'] : [];
    req.body['interests'] = Array.isArray(req.body['interests']) ?
      req.body['interests'] : [req.body['interests']];

    // Map form input to template variables.
    const templateData = {
      firstName: req.body['first-name'],
      lastName: req.body['last-name'],
      emailAddress: req.body['email'],
      organization: req.body['organization'],
      title: req.body['title'],
      country: req.body['country'],
      city: req.body['city'],
      message: req.body['message'],
      interests: req.body['interests'].join(', '),
    };

    const params = {
      Destination: {
        ToAddresses: process.env.RECEIVE_CONTACT_FORM_EMAILS.split(','),
      },
      Source: process.env.ALERT_SENDER_EMAIL,
      Template: 'ContactFormTemplate',
      TemplateData: JSON.stringify(templateData),
    };

    var sendPromise = new AWS.SES(AWSConfig).sendTemplatedEmail(params).promise();
    await sendPromise;

    const redirectURL = (process.env.SITE_URL + '/thank-you/contact')
      // Remove duplicate forward slashes.
      .replace(/([^:]\/)\/+/g, "$1");

    res.writeHead(303, {'Location': redirectURL});
    res.end();
  } catch (err) {
    console.error(err);
    res.writeHead(303, {'Location': errorRedirectURL});
    res.end();
  }
});

router.post('/submission-form', async (req, res, next) => {
  try {
    // Sanitize form inputs.
    sanitizeBody('first-name').stripLow().trim().escape();
    sanitizeBody('last-name').stripLow().trim().escape();
    sanitizeBody('email').normalizeEmail();
    sanitizeBody('organization').stripLow().trim().escape();
    sanitizeBody('title').stripLow().trim().escape();
    sanitizeBody('country').stripLow().trim().escape();
    sanitizeBody('city').stripLow().trim().escape();
    sanitizeBody('resource-title').stripLow().trim().escape();
    sanitizeBody('resource-organization').stripLow().trim().escape();
    sanitizeBody('resource-link').stripLow().trim();
    req.body['resource-link'] = encodeURI(req.body['resource-link']);
    sanitizeBody('resource-description').stripLow().trim().escape();
    sanitizeBody('resource-topics.*').stripLow().trim().escape();
    sanitizeBody('resource-additional-info').stripLow().trim().escape();

    // Handle empty array (i.e. checkboxes not selected).
    // Must give at least a default value or else e-mail alerts will not send.
    req.body['resource-topics'] = (typeof req.body['resource-topics'] !== 'undefined') ?
      req.body['resource-topics'] : [];
    req.body['resource-topics'] = Array.isArray(req.body['resource-topics']) ?
      req.body['resource-topics'] : [req.body['resource-topics']];

    let submission = await sequelize.transaction(async (t) => {
      let resource = await models.resource.create({
        title: req.body['resource-title'],
        organization: req.body['resource-organization'],
        url: req.body['resource-link'],
        description: req.body['resource-description'],
      }, { transaction: t });

      return models.submission.create({
        resource_id: resource.dataValues.uuid,
        submitter_country_id: req.body['country'],
        submitter_name: req.body['first-name'] + ' ' + req.body['last-name'],
        submitter_organization: req.body['organization'],
        submitter_title: req.body['title'],
        submitter_email: req.body['email'],
        submitter_city: req.body['city'],
        tags: req.body['resource-topics'],
        notes: req.body['resource-additional-info'],
      }, { transaction: t });
    });

    // Map form input to template variables.
    const templateData = {
      submissionUUID: submission.dataValues.uuid,
      resourceUUID: submission.dataValues.resource_id,
      resourceTitle: req.body['resource-title'],
      resourceOrganization: req.body['resource-organization'],
      resourceURL: req.body['resource-link'],
      resourceDescription: req.body['resource-description'],
      resourceTags: req.body['resource-topics'].join(', '),
      additionalInfo: req.body['resource-additional-info'],
      firstName: req.body['first-name'],
      lastName: req.body['last-name'],
      emailAddress: req.body['email'],
      organization: req.body['organization'],
      title: req.body['title'],
      country: req.body['country'],
      city: req.body['city'],
    };

    const params = {
      Destination: {
        ToAddresses: process.env.RECEIVE_RESOURCE_FORM_EMAILS.split(','),
      },
      Source: process.env.ALERT_SENDER_EMAIL,
      Template: 'ResourceFormTemplate',
      TemplateData: JSON.stringify(templateData),
    };

    const sendPromise = new AWS.SES(AWSConfig).sendTemplatedEmail(params).promise();
    await sendPromise;

    let redirectURL = process.env.SITE_URL + '/thank-you/submit-resource';
    // Remove duplicate forward slashes.
    redirectURL = redirectURL.replace(/([^:]\/)\/+/g, "$1");

    res.writeHead(303, {'Location': redirectURL});
    res.end();
  } catch (err) {
    console.error(err);
    res.writeHead(303, {'Location': errorRedirectURL});
    res.end();
  }
});

router.get('/resources/', [
    check('limit')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
    check('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      // Set parameter defaults here.
      const limit = req.query.limit ? req.query.limit : 100;
      const offset = req.query.offset ? req.query.offset : 0;
      const tsvectorColumn = 'tsv';

      // Filter specifications.
      const filterList = {
        'tags': {
          association: 'tags',
          model: 'tag',
          filteringField: 'name',
          retrieveFields: ['name'],
        },
        'type': {
          association: 'content_types',
          model: 'content_type',
          filteringField: 'id',
          retrieveFields: ['id'],
        },
        'topic': {
          association: 'topics',
          model: 'topic',
          filteringField: 'topic',
          retrieveFields: ['id'],
        },
        'language': {
          association: 'languages',
          model: 'language',
          filteringField: 'ietf_tag',
          retrieveFields: ['ietf_tag'],
        },
        'country': {
          association: 'countries',
          model: 'country',
          filteringField: 'iso_alpha3',
          retrieveFields: ['iso_alpha3'],
        },
      };

      // Set filters.
      let filters = {
        publish: true, // Default filter for published resources only.
      };
      let assocFilters = {};

      for (const filterName in filterList) {
        // Check whether the specified filter matches a query string parameter.
        if (filterName in req.query) {
          const filter = filterList[filterName];
          const filterField = filter.filteringField;

          // Get value to filter for from querysting.
          let filterValue = req.query[filterName];

          // Check whether field to filter on exists on the resource model.
          if (filterField in models.resource.attributes) {
            const isArrayField = (models.resource.attributes[filterField].type
              .toString().indexOf('[]') > -1);

            // If the field is defined in the model to be an array and the value
            // is not given as an array, wrap the value in an array.
            if (isArrayField && !Array.isArray(filterValue)) {
              filterValue = [filterValue];
            }

            // Add filter to direct filters.
            if (isArrayField && Array.isArray(filterValue)) {
              // The $overlap criterion results in inclusive filtering, while
              // the $contains criterion results in exclusive filtering.
              filters[filter.filteringField] = {
                $overlap: filterValue,
              };
            } else if (Array.isArray(filterValue)) {
              // If the field is defined as a single value, but the values are
              // in an array, we want the $in criterion.
              filters[filter.filteringField] = {
                $in: filterValue,
              }
            } else {
              filters[filter.filteringField] = filterValue;
            }
          } else if ('association' in filter &&
            filter.association in models.resource.associations) {
            // Add filters to many-to-many association filters.
            assocFilters[filterName] = req.query[filterName];
          }
          // Ignore unmatched filters.
        }
      }

      // Set filters for many-to-many relations.
      let associations = [];

      for (const filterName in assocFilters) {
        const filter = filterList[filterName];
        const filterValues = assocFilters[filterName];

        // Only use the filter if there are filtering values provided.
        if (filterValues.length) {
          let association = {};
          association.model = models[filter.model];
          association.attributes = filter.retrieveFields;
          association.through = {
            attributes: [],
          };
          association.where = {};
          association.where[filter.filteringField] = filterValues;
          association.required = true;

          associations.push(association);
        }
      }

      // Set result ordering criteria.
      let orderingCols = [];

      // This depends on having a column on the table that holds the document
      // vector (i.e. tsvector) of the columns to be available for search.
      // Here, tsmatch is a custom PL/pgSQL convenience function.
      if ('search' in req.query) {
        filters = {
          $and: [
            filters,
            sequelize.fn('tsmatch',
              sequelize.literal(tsvectorColumn),
              sequelize.fn('phraseto_tsquery',
                'sdg.english_nostop', // Custom text search dictionary.
                req.query.search,
              ),
            ),
          ],
        };

        // Order search results by cover density ranking.
        orderingCols.push([
          sequelize.fn('ts_rank_cd',
            'tsv',
            sequelize.fn('phraseto_tsquery',
              'sdg.english_nostop', // Custom text search dictionary.
              req.query.search,
            ),
          ),
          'DESC',
        ]);
      } else {
        // Order by publication date by default w/ NULL last.
        orderingCols.push([
          sequelize.col('date_published'),
          'DESC NULLS LAST',
        ]);
      }

      models.resource.findAndCountAll({
        include: associations,
        limit: limit,
        offset: offset,
        where: filters,
        order: orderingCols,
        distinct: true,
        subQuery: false,
        raw: true,
      }).then((results) => {
        res.send(results);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/resources/:uuid', [
    check('uuid')
      .isUUID()
      .withMessage('must provide a valid UUID format ID'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.uuid;

      models.resource.findById(uuid).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/content_types/', async (req, res, next) => {
    try {
      const sql = "SELECT array_to_json(array_agg(json_build_object('id', id, 'name', name))) AS content_type FROM sdg.content_type WHERE id IN (SELECT DISTINCT(id) FROM sdg.content_type INNER JOIN sdg.resource_content_types ON id = content_type_id);";

      sequelize.query(sql, { type: sequelize.QueryTypes.SELECT })
        .then((rows) => {
          res.send(rows[0].content_type);
        });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/content_types/:id', async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.id;

      models.content_type.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/topics/', [
    check('limit')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
    check('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const sql = "SELECT array_to_json(array_agg(json_build_object('topic', topic.topic, 'label', topic.label, 'subtopics', (SELECT COALESCE(array_to_json(array_agg(subtopic)), '[]') FROM sdg.topic AS subtopic WHERE subtopic.path <@ topic.path AND subtopic.path <> topic.path)))) AS topic FROM sdg.topic WHERE topic.path ~ '*{,1}';";

      sequelize.query(sql, { type: sequelize.QueryTypes.SELECT })
        .then((rows) => {
          res.send(rows[0].topic);
        });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/topics/:id', async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.id;

      models.topic.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/languages/', [
    check('limit')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
    check('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const sql = "SELECT array_to_json(array_agg(json_build_object('ietf_tag', ietf_tag, 'name', name, 'label', label))) AS language FROM sdg.language WHERE ietf_tag IN (SELECT DISTINCT(ietf_tag) FROM sdg.language INNER JOIN sdg.resource_languages ON ietf_tag = language_id);";

      sequelize.query(sql, { type: sequelize.QueryTypes.SELECT })
        .then((rows) => {
          res.send(rows[0].language);
        });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/languages/:ietf_tag', async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.ietf_tag;

      models.language.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/regions/', [
    check('limit')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
    check('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.region.findAll().then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/regions/:m49', [
    check('m49')
      .isInt()
      .isLength({ min: 3, max: 3 })
      .withMessage('must provide a valid M49 format code'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.m49;

      models.region.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/countries/', [
    check('limit', 'must be a positive integer')
      .optional()
      .isInt({ min: 0 }),
    check('offset', 'must be a positive integer')
      .optional()
      .isInt({ min: 0 }),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const sql = "SELECT array_to_json(array_agg(json_build_object('iso_alpha3', iso_alpha3, 'region_id', region_id, 'name', name))) AS country FROM sdg.country WHERE iso_alpha3 IN (SELECT DISTINCT(iso_alpha3) FROM sdg.country INNER JOIN sdg.resource_countries ON iso_alpha3 = country_id);";

      sequelize.query(sql, { type: sequelize.QueryTypes.SELECT })
        .then((rows) => {
          res.send(rows[0].country);
        });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/countries/:alpha3', [
    check('alpha3')
      .isAlpha()
      .isLength({ min: 3, max: 3 })
      .withMessage('must provide a valid ISO 3166-1 Alpha 3 format country code'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.alpha3;

      models.country.findById(id, {
        attributes: ['iso_alpha3', 'region_id', 'name'],
      }).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/news/', [
    check('limit')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
    check('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    // Validate paramaters.
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      // Set parameter defaults here.
      const limit = ('limit' in req.query) ? req.query.limit : 100;
      const offset = ('offset' in req.query) ? req.query.offset : 0;

      // List detailing filter specifications.
      const filterList = {
        'tags': {
          filteringField: 'tags',
        },
      };

      // Set filters.
      let filters = {
        publish: true, // Filter on publication flag by default.
      };

      for (let filterName in filterList) {
        if (filterName in req.query) {
          let filter = filterList[filterName];

          if (filter.filteringField in models.news.attributes) {
            const filterValues = req.query[filterName].split(',');

            // Add filter to direct filters.
            if (filterName === 'tags' && Array.isArray(filterValues)) {
              filters[filter.filteringField] = {
                $overlap: filterValues,
              };
            } else {
              if (filter.operator) {
                filters[filter.filteringField] = {};
                filters[filter.filteringField][filter.operator] = filterValues;
              } else {
                filters[filter.filteringField] = filterValues;
              }
            }
          }
          // Ignore unmatched filters.
        }
      }

      models.news.findAndCountAll({
        limit: limit,
        offset: offset,
        where: filters,
        order: [
          [sequelize.col('created_at'), 'DESC'],
        ],
      }).then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/news/:uuid', [
    check('uuid')
      .isUUID()
      .withMessage('must provide a valid UUID'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.uuid;

      models.news.findById(uuid).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/events/', [
    check('limit')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
    check('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      // Set parameter defaults here.
      const limit = ('limit' in req.query) ? req.query.limit : 100;
      const offset = ('offset' in req.query) ? req.query.offset : 0;

      // List detailing filter specifications.
      const filterList = {
        'tags': {
          filteringField: 'tags',
        },
      };

      // Set filters.
      let filters = {
        publish: true, // Filter on publication flag by default.
      };

      for (const filterName in filterList) {
        if (filterName in req.query) {
          let filter = filterList[filterName];

          if (filter.filteringField in models.events.attributes) {
            const filterValues = req.query[filterName].split(',');

            // Add filter to direct filters.
            if (Array.isArray(filterValues)) {
              filters[filter.filteringField] = {
                $contains: filterValues,
              };
            } else {
              filters[filter.filteringField] = filterValues;
            }
          }
          // Ignore unmatched filters.
        }
      }

      models.event.findAll({
        limit: limit,
        offset: offset,
        where: filters,
        order: [
          [sequelize.col('start_time'), 'DESC'],
        ],
      }).then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/events/:uuid', [
    check('uuid')
      .isUUID()
      .withMessage('must provide a valid UUID'),
  ], async (req, res, next) => {
    // Process validation results.
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      const id = req.params.uuid;

      models.event.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.error(err);
      return res.status(500);
    }
  }
);

router.get('/tags/news', async(req, res, next) => {
  try {
    const sql = squel.select()
      .from('sdg.news n, unnest(n.tags) AS tag')
      .field('tag')
      .group('tag')
      .order('tag')
      .toString();

    sequelize.query(sql, { type: sequelize.QueryTypes.SELECT })
      .then((rows) => {
        let unique_tags = [];
        rows.map((row) => {
          unique_tags.push(row.tag);
        });

        res.send(unique_tags);
      });
  } catch (err) {
    console.error(err);
    res.status(500).send(err);
  }
});

module.exports = router;
