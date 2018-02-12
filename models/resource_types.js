'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_content_types', {
    resource_id: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
      },
    },
    content_type_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      references: {
        model: sequelize.models.content_type,
        key: 'id',
      },
    },
  }, {
    tableName: 'resource_content_types',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'resource_id',
    });
    Model.belongsTo(models.content_type, {
      foreignKey: 'content_type_id',
    });
  };

  return Model;
};
