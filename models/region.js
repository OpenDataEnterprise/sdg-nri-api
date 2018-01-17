'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('region', {
    m49: {
      type: DataTypes.CHAR(3),
      primaryKey: true 
    },
    path: {
      type: DataTypes.TEXT,
    },
    name: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'region',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};

