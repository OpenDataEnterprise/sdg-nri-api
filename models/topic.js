'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('topic', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    topic: {
      type: DataTypes.TEXT,
    },
    path: {
      type: DataTypes.TEXT,
    },
    label: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'topic',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsToMany(models.resource, {
      through: 'resource_topics',
      foreignKey: 'topic_id',
    });
  };

  return Model;
};
