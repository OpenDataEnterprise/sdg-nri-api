'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_languages', {
    resource_id: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
      },
    },
    language_id: {
      type: DataTypes.TEXT,
      primaryKey: true,
      references: {
        model: sequelize.models.language,
        key: 'ietf_tag',
      },
    },
  }, {
    tableName: 'resource_languages',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'resource_id',
    });
    Model.belongsTo(models.language, {
      foreignKey: 'language_id',
    });
  };

  return Model;
};