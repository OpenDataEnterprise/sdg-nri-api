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
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE,
      }
    },
    submitter_name: {
      type: DataTypes.TEXT,
    },
    submitter_organization: {
      type: DataTypes.TEXT,
    },
    submitter_email: {
      type: DataTypes.TEXT,
    },
    status: {
      type: DataTypes.TEXT,
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
  };

  return Model;
};

