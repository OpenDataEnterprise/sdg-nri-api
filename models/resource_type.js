'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('content_type', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'content_type',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};
