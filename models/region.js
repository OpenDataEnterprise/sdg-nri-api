'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('region', {
    m49: {
      type: DataTypes.STRING,
      primaryKey: true 
    },
    hierarchy: {
      type: DataTypes.STRING,
    },
    name: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'region',
    
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

