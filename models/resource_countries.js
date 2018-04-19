'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_countries', {
    resource_id: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
      },
    },
    country_id: {
      type: DataTypes.CHAR(3),
      primaryKey: true,
      references: {
        model: sequelize.models.country,
        key: 'iso_alpha3',
      },
    },
  }, {
    tableName: 'resource_countries',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'resource_id',
    });
    Model.belongsTo(models.country, {
      foreignKey: 'country_id',
    });
  };

  return Model;
};
