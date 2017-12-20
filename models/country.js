'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('country', {
    iso_alpha3: {
      type: DataTypes.STRING,
      primaryKey: true 
    },
    region_m49: {
      type: DataTypes.STRING,
    },
    name: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'country',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

