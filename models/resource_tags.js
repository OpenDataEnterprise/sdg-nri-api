'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_tags', {
    resource_id: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
      },
    },
    tag_id: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.tag,
        key: 'uuid',
      },
    },
  }, {
    tableName: 'resource_tags',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'resource_id',
    });
    Model.belongsTo(models.tag, {
      foreignKey: 'tag_id',
    });
  };

  return Model;
};
