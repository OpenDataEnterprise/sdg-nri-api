'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('region', {
    m49: {
      type: DataTypes.STRING,
      primaryKey: true 
    },
    path: {
      type: DataTypes.STRING,
    },
    name: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'region',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};

