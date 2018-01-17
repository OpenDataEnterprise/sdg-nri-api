'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource_type', {
    id: {
      type: DataTypes.INTEGER,
      field: 'id',
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'resource_type',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};

