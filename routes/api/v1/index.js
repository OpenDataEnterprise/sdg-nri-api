'use strict';
const express = require('express');
const router = express.Router();
const { check, validationResult } = require('express-validator/check');
const { matchedData, sanitize } = require('express-validator/filter');
const Liana = require('forest-express-sequelize');
const models = require('../../../models');

router.get('/', (req, res) => {
  try {
    res.send(req.query);
  } catch (err) {
    console.log(err);
  }
});

router.get('/resources/', [
    check('limit').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('offset').optional().isInt({ min: 0 }).withMessage('must be a positive integer'),
    check('country').optional().isAlpha().withMessage('must contain only letters'),
  ], async (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      return res.status(422).json({ errors: errors.mapped() });
    }

    try {
      models.resource.findAll().then((values) => {
        res.send(values);
      });
    } catch (err) {
      console.log(err);
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
