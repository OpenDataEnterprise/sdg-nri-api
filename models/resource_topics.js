'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_topics', {
    resource_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
      },
    },
    topic_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      references: {
        model: sequelize.models.topic,
        key: 'id',
      },
    },
  }, {
    tableName: 'resource_topics',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.resource, {
      foreignKey: 'resource_id',
    });
    Model.belongsTo(models.topic, {
      foreignKey: 'topic_id',
    });
  };

  return Model;
};
