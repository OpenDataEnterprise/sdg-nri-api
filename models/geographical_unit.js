'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('geographical_unit', {
    name: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'geographical_unit',

    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

