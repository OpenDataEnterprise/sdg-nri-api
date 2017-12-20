'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_topic', {
    topic: {
      type: DataTypes.STRING,
    },
    label: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'resource_topic',
    
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

