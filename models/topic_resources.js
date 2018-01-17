'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('topic_resources', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    resource_id: {
      type: DataTypes.INTEGER,
      references: {
        model: sequelize.models.resource,
        key: 'uuid',
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE
      }
    },
    topic_id: {
      type: DataTypes.INTEGER,
      references: {
        model: sequelize.models.topic,
        key: 'id',
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE
      }
    },
  }, {
    tableName: 'topic_resources',
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

