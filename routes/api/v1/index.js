'use strict';
const express = require('express');
const router = express.Router();
const { check, validationResult } = require('express-validator/check');
const { matchedData, sanitize } = require('express-validator/filter');
const squel = require('squel');
const models = require('../../../models');
const sequelize = models.sequelize;

router.get('/', (req, res) => {
  try {
    res.status(200).send();
  } catch (err) {
    console.log(err);
    res.status(500).send();
  }
});

router.get('/resources/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    // Validate paramaters.
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      // Set parameter defaults here.
      const limit = req.query.limit ? req.query.limit : 100;
      const offset = req.query.offset ? req.query.offset : 0;

      // List detailing filter specifications.
      let filterList = {
        'type': {
          model: 'resource_type',
          filteringField: 'resource_id',
          retrieveFields: [],
        },
        'country': {
          model: 'country',
          filteringField: 'country_id',
          retrieveFields: [],
        },
        'topic': {
          association: 'topics',
          model: 'topic',
          filteringField: 'tag',
          retrieveFields: ['id'],
        },
        'language': {
          association: 'languages',
          model: 'language',
          filteringField: 'ietf_tag',
          retrieveFields: ['ietf_tag'],
        },
      };

      // Set filters.
      let filters = {
        publish: true, // Default filter - only published resources.
      };
      let assocFilters = {};

      for (let filterName in filterList) {
        if (filterName in req.query) {
          let filter = filterList[filterName];

          if (filter.filteringField in models.resource.attributes) {
            // Add filter to direct filters.
            filters[filter.filteringField] = req.query[filterName];
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

      for (let filterName in assocFilters) {
        let filter = filterList[filterName];
        let filterValues = assocFilters[filterName];

        // Only use the filter if there are filtering values provided.
        if (filterValues.length) {
          let association = {};
          association.model = models[filter.model];
          association.attributes = filter.retrieveFields;
          association.through = {
            attributes: [],
          };
          association.where = {};
          association.where[filter.filteringField] = filterValues.split(',');
          association.required = true;

          associations.push(association);
        }
      }

      models.resource.findAndCountAll({
        include: associations,
        limit: limit,
        offset: offset,
        where: filters,
        order: [
          [sequelize.col('date_published'), 'DESC'],
        ],
        distinct: true,
        subQuery: false,
        raw: false,
        //logging: console.log,
      }).then((results) => {
        res.send(results);
      });
    } catch (err) {
      console.log(err);
      return res.status(500);
    }
  }
);

router.get('/resources/:uuid', [
    check('uuid').isUUID().withMessage('must provide a valid UUID format ID'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.uuid;

      models.resource.findById(uuid).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/resource_types/', async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.resource_type.findAll().then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/resource_types/:id', async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.id;

      models.resource_type.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
    }
  }
);


router.get('/topics/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.topic.findAll().then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/topics/:id', async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.id;

      models.topic.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/languages/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.language.findAll().then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/languages/:id', async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.id;

      models.language.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/regions/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.region.findAll({
      }).then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/regions/:m49', [
    check('m49', 'must provide a valid M49 format code')
      .isInt()
      .isLength({ min: 3, max: 3 }),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.m49;

      models.region.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
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
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.country.findAll({
        attributes: ['iso_alpha3', 'region_id', 'name'],
      }).then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/countries/:alpha3', [
    check('alpha3', 'must provide a valid ISO 3166-1 Alpha 3 format country code')
      .isAlpha()
      .isLength({ min: 3, max: 3 }),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.alpha3;

      models.country.findById(id, {
        attributes: ['iso_alpha3', 'region_id', 'name'],
      }).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/news/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
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
      let filterList = {
        'tags': {
          filteringField: 'tags',
          retrieveFields: [],
        },
      };

      // Set filters.
      let filters = {};

      for (let filterName in filterList) {
        if (filterName in req.query) {
          let filter = filterList[filterName];

          if (filter.filteringField in models.news.attributes) {
            let filterValues = req.query[filterName].split(',');

            console.log(filterValues);
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

      console.log(filters);
      models.news.findAndCountAll({
        limit: limit,
        offset: offset,
        where: filters,
        logging: console.log,
      }).then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/news/:uuid', [
    check('uuid').isUUID().withMessage('must provide a valid UUID'),
  ], async (req, res, next) => {
    // Validate parameters.
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.uuid;

      models.news.findById(uuid).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/events/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.event.findAll().then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/events/:uuid', [
    check('uuid').isUUID().withMessage('must provide a valid UUID'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      let id = req.params.uuid;

      models.event.findById(id).then((value) => {
        res.send(value);
      });
    } catch (err) {
      console.log(err);
    }
  }
);

router.get('/tags/news', async(req, res, next) => {
  try {
    let sql = squel.select()
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
    console.log(err);
    res.status(500).send(err);
  }
});

module.exports = router;
