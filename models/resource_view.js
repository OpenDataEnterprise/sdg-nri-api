'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_view', {
    uuid: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
      },
    },
    tags: {
      type: DataTypes.ARRAY(DataTypes.TEXT),
    },
  }, {
    tableName: 'resource_view',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'uuid',
    });
  };

  return Model;
};