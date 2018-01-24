'use strict';
const express = require('express');
const router = express.Router();
const { check, validationResult } = require('express-validator/check');
const { matchedData, sanitize } = require('express-validator/filter');
const Liana = require('forest-express-sequelize');
const models = require('../../../models');

router.get('/', (req, res) => {
  try {
    res.send();
  } catch (err) {
    console.log(err);
  }
});

router.get('/resources/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('country').optional().isAlpha().withMessage('must contain only letters'),
  ], async (req, res, next) => {
    // Validate paramaters.
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(422).json({ errors: errors.mapped() }).send();
    }

    try {
      // Set parameter defaults here.
      const limit = req.query.limit ? req.params.limit : 100;
      const offset = req.query.offset ? req.params.offset : 0;

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
            filters[filterName] = req.query[filterName];
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
          let assocation = {};
          assocation.model = models[filter.model];
          assocation.attributes = filter.retrieveFields;
          assocation.through = {
            attributes: [],
          };
          assocation.where = {};
          assocation.where[filter.filteringField] = filterValues.split(',');

          associations.push(assocation);
        }
      }

      models.resource.findAll({
        attributes: [
          'title',
          'organization',
          'url',
          'date_published',
          'image_url',
          'description',
          'publish',
        ],
        include: associations,
        limit: limit,
        offset: offset,
        where: filters,
        raw: false,
      }).then((results) => {
        res.send(results);
      });
    } catch (err) {
      console.log(err);
      res.status(500).send();
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
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.news.findAll().then((values) => {
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


module.exports = router;
