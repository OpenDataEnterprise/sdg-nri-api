'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('submission', {
    uuid: {
      type: DataTypes.UUID,
      defaultValue: sequelize.literal('uuid_generate_v1mc()'),
      primaryKey: true,
    },
    resource_id: {
      type: DataTypes.UUID,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
      },
    },
    country_id: {
      type: DataTypes.CHAR(3),
      references: {
        model: sequelize.models.country,
        key: 'iso_alpha3',
      },
    },
    submitter_name: {
      type: DataTypes.TEXT,
    },
    submitter_organization: {
      type: DataTypes.TEXT,
    },
    submitter_title: {
      type: DataTypes.TEXT,
    },
    submitter_email: {
      type: DataTypes.TEXT,
    },
    submitter_city: {
      type: DataTypes.TEXT,
    },
    status: {
      type: DataTypes.TEXT,
      references: {
        model: sequelize.models.submission_status,
        key: 'status',
      },
      defaultValue: 'Unreviewed',
    },
    notes: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'submission',
    underscored: true,
    timestamps: true,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'resource_id',
    });
    Model.belongsTo(models.country, {
      foreignKey: 'country_id',
    });
    Model.belongsTo(models.submission_status, {
      foreignKey: 'status',
    });
  };

  return Model;
};